namespace Musys.IR {
    public abstract class UnarySSA: Instruction {
        protected        Value _operand;
        protected unowned Type _operand_type;
        public Value operand {
            get { return _operand; }
            set {
                if (value == _operand)
                    return;
                if (value != null) {
                    type_match_or_crash(_operand_type, value.value_type,
                        {Log.FILE, Log.METHOD, Log.LINE});
                }
                replace_use(_operand, value, operands.front());
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
        public override void on_parent_finalize() {
            _clean_operand();
            _nodeof_this = null;
        }
        public override void on_function_finalize() {
            _operand     = null;
            _nodeof_this = null;
        }

        protected UnarySSA.C1(Value.TID tid, OpCode opcode, Type type, Type op_type)
        {
            base.C1 (tid, opcode, type);
            this._operand_type = op_type;
            new UnaryOpUse(this).attach_back(this);
        }
    }

    private sealed class UnaryOpUse: Use {
        public new UnarySSA user {
            get { return static_cast<UnarySSA>(_user); }
        }
        public override Value? usee {
            get { return user.operand;  }
            set { user.operand = value; }
        }
        public UnaryOpUse(UnarySSA user) { base.C1(user); }
    }

    public sealed class UnaryOpSSA: UnarySSA {
        public override void accept(IValueVisitor visitor) {
            visitor.visit_inst_unary(this);
        }

        public UnaryOpSSA.raw(OpCode opcode, Type type) {
            base.C1(UNARYOP_SSA, opcode, type, type);
        }
        public UnaryOpSSA.as_neg(Value value) {
            unowned var type = value.value_type;
            OpCode opcode;
            if    (type.is_float)   opcode = FNEG;
            else if (type.is_int)   opcode = INEG;
            else crash(@"NEG operation requires int/float, but got $type");

            this.raw(opcode, type);
            this.operand = value;
        }
        public UnaryOpSSA.as_not(Value value) {
            var type = value_int_or_crash(value);
            this.raw(NOT, type);
            this.operand = operand;
        }
    }
}
