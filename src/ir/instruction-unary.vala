namespace Musys.IR {
    /**
     * === 单操作数指令(基类) ===
     *
     * 只有一个操作数的指令, 包括取反、取负、存储单元加载等.
     * 把这些指令合并到一个基类里是为了减少 Use 的工作量.
     */
    public abstract class UnarySSA: Instruction {
        protected        Value _operand;
        protected unowned Type _operand_type;
        protected UnaryOpUse   _uoperand;

        protected virtual void _check_operand(Value? operand) {}
        public Value operand {
            get { return _operand; }
            set {
                if (value == _operand)
                    return;
                if (value != null) {
                    type_match_or_crash(_operand_type, value.value_type,
                        {Log.FILE, Log.METHOD, Log.LINE});
                }
                replace_use(_operand, value, _uoperand);
                _operand = value;
            }
        }
        protected void _clean_operand()
        {
            if (_operand == null)
                return;
            _operand.remove_use_as_usee(operands.front());
            _operand = null;
        }
        public override void on_function_finalize() { _fast_clean(); }
        public override void on_parent_finalize()   { _deep_clean(); }
        protected new void _deep_clean() {
            _clean_operand();
            base._deep_clean();
        }
        protected new void _fast_clean() {
            _clean_operand();
            base._fast_clean();
        }

        protected UnarySSA.C1(Value.TID tid, OpCode opcode, Type type, Type op_type)
        {
            base.C1 (tid, opcode, type);
            this._operand_type = op_type;
            this._uoperand = new UnaryOpUse();
            this._uoperand.attach_back(this);
        }
        class construct {
            _istype[TID.UNARY_SSA] = true;
        }

        protected sealed class UnaryOpUse: Use {
            public new UnarySSA user {
                get { return static_cast<UnarySSA>(_user); }
            }
            public override Value? usee {
                get { return user.operand; }
                set { user.operand = value; }
            }
        }
    }

    /**
     * === 单操作数指令 ===
     *
     * 包含取负、取反等一系列操作.
     *
     * ''语法'': `%<id> = <opcode> <value_type>, <operand_type> <operand>`
     * - ``opcode``: 操作码 not, ineg 或 fneg
     *
     * 操作数:
     * - `[0] = operand` 源操作数
     */
    public sealed class UnaryOpSSA: UnarySSA {
        public override void accept(IValueVisitor visitor) {
            visitor.visit_inst_unary(this);
        }
        protected override void _check_operand(Value? value)
        {
            if (value == null)
                return;
            type_match_or_crash(this.value_type,
                                value.value_type,
                                Musys.SourceLocation.current());
        }

        public UnaryOpSSA.raw(OpCode opcode, Type type) {
            base.C1(UNARYOP_SSA, opcode, type, type);
        }
        public UnaryOpSSA.as_neg(Value value) {
            unowned var type = value.value_type;
            OpCode opcode;
            if    (type.is_float) opcode = FNEG;
            else if (type.is_int) opcode = INEG;
            else crash(@"NEG operation requires int/float, but got $type");

            this.raw(opcode, type);
            this.operand = value;
        }
        public UnaryOpSSA.as_not(Value value) {
            var type = value_int_or_crash(value);
            this.raw(NOT, type);
            this.operand = value;
        }

#if false
        private static void _check_operand_by_opcode(UnaryOpSSA self, Value? value)
        {
            var opcode = self.opcode;
            switch (opcode) {
            case OpCode.NOT: case OpCode.INEG:
                value_int_or_crash(value,
                    opcode == INEG? "for this being an INEG instruction"
                                  : "for this being a NOT instruction");
                break;
            case OpCode.FNEG:
                value_float_or_crash(value, "for this being a FNEG instruction");
                break;
            default:
                assert_not_reached();
            }
        }
#endif
    }
}
