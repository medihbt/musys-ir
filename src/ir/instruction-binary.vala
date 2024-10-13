namespace Musys.IR {
    /**
     * === 双操作数指令 ===
     *
     * 顾名思义. 双操作数指令要么是算术运算指令，要么是逻辑运算指令.
     *
     * ==== 操作数表 ====
     *
     * * ``[0] = lhs``: 左操作数
     *
     * * ``[1] = rhs``: 右操作数
     *
     * ==== 文本格式 ====
     *
     * * 整数加/减/乘指令: ``%<id> = <opcode> <nsw|nuw> <type> <lhs>, <rhs>``, 其中 opcode = add, sub, mul
     *
     * * 其他算术指令: ``%<id> = <opcode> <type> <lhs>, <rhs>``, 其中 opcode = fadd,...,frem;sdiv,udiv,srem,urem
     *
     * * 其他指令: ``%<id> = <opcode> <type> <lhs>, <type> <rhs>``, 其中 opcode = and,or,...,ashr
     */
    public class BinarySSA: Instruction {
        private Value _lhs;
        private Value _rhs;
        private unowned Use _ulhs;
        private unowned Use _urhs;
        /** 左操作数 ([0] = lhs) */
        public Value lhs {
            get { return _lhs; }
            set { set_usee_type_match_self(ref _lhs, value, _ulhs); }
        }
        /** 右操作数 ([1] = rhs) */
        public Value rhs {
            get { return _rhs; }
            set {
                if (!opcode.is_shift_op()) {
                    set_usee_type_match_self(ref _rhs, value, _urhs);
                } else {
                    value_int_or_crash(value, "%s", "BinarySSA.rhs::set()");
                    User.set_usee_always(ref _rhs, value, _urhs);
                }
            }
        }

        /**
         * 是否把操作数视为有符号的.
         *
         * 在算术二元表达式中, 这个 is_signed 会作用于全体操作数. 在移位表达式中,
         * is_signed 会作用于被移位的操作数.
         */
        public bool is_signed{get;}

        public override void on_parent_finalize () {
            lhs = null; rhs = null;
            base._deep_clean();
        }
        public override void on_function_finalize () {
            _lhs = null; _rhs = null;
            base._fast_clean();
        }
        public override void accept(IValueVisitor visitor) {
            visitor.visit_inst_binary(this);
        }

        public BinarySSA.empty(OpCode opcode, Type type) {
            base.C1(BINARY_SSA, opcode, type);
            _ulhs = new BinaryLHSUse(this).attach_back(this);
            _urhs = new BinaryRHSUse(this).attach_back(this);
        }
        public BinarySSA.nocheck(OpCode opcode, Type type, Value lhs, Value rhs, bool is_signed) {
            base.C1(BINARY_SSA, opcode, type);
            this._is_signed = is_signed;
            _ulhs = new BinaryLHSUse(this).attach_back(this);
            _urhs = new BinaryRHSUse(this).attach_back(this);
            this._lhs = lhs;
            this._rhs = rhs;
            _lhs.add_use_as_usee(_ulhs);
            _rhs.add_use_as_usee(_urhs);
        }

        public BinarySSA.as_add(Value lhs, Value rhs, bool is_signed = true)
                    throws TypeMismatchErr {
            Type type = checkop_same(lhs, rhs, PRIMITIVE_TYPE, "BinarySSA::as_add");
            this.nocheck(type.is_int? OpCode.ADD: OpCode.FADD, type, lhs, rhs, is_signed);
        }
        public BinarySSA.as_sub(Value lhs, Value rhs, bool is_signed = true)
                    throws TypeMismatchErr {
            Type type = checkop_same(lhs, rhs, PRIMITIVE_TYPE, "BinarySSA::as_sub");
            this.nocheck(type.is_int? OpCode.SUB: OpCode.FSUB, type, lhs, rhs, is_signed);
        }
        public BinarySSA.as_mul(Value lhs, Value rhs, bool is_signed = true)
                    throws TypeMismatchErr {
            Type type = checkop_same(lhs, rhs, PRIMITIVE_TYPE, "BinarySSA::as_mul");
            this.nocheck(type.is_int? OpCode.MUL: OpCode.FMUL, type, lhs, rhs, is_signed);
        }
        public BinarySSA.as_idiv(Value lhs, Value rhs, bool is_signed = true)
                    throws TypeMismatchErr {
            Type type = checkop_same(lhs, rhs, INT_TYPE, "BinarySSA::as_idiv");
            this.nocheck(is_signed? OpCode.SDIV: OpCode.UDIV, type, lhs, rhs, is_signed);
        }
        public BinarySSA.as_fdiv(Value lhs, Value rhs)
                    throws TypeMismatchErr {
            Type type = checkop_same(lhs, rhs, FLOAT_TYPE, "BinarySSA::as_fdiv");
            this.nocheck(FDIV, type, lhs, rhs, true);
        }
        public BinarySSA.as_div(Value lhs, Value rhs, bool is_signed = true)
                    throws TypeMismatchErr {
            Type.TID tidreq;
            OpCode   opcode;
            if (lhs.value_type.is_float) {
                tidreq = FLOAT_TYPE; is_signed = true;
                opcode = FDIV;
            } else {
                tidreq = INT_TYPE;
                opcode = is_signed? OpCode.SDIV: OpCode.UDIV;
            }
            this.nocheck(opcode,
                checkop_same(lhs, rhs, tidreq, "BinarySSA::as_div"),
                lhs, rhs, true);
        }
        public BinarySSA.as_irem(Value lhs, Value rhs, bool is_signed = true)
                    throws TypeMismatchErr {
            Type type = checkop_same(lhs, rhs, INT_TYPE, "BinarySSA::as_irem");
            this.nocheck(is_signed? OpCode.SREM: OpCode.UREM, type, lhs, rhs, is_signed);
        }
        public BinarySSA.as_frem(Value lhs, Value rhs)
                    throws TypeMismatchErr {
            Type type = checkop_same(lhs, rhs, FLOAT_TYPE, "BinarySSA::as_irem");
            this.nocheck(FREM, type, lhs, rhs, true);
        }
        public BinarySSA.as_rem(Value lhs, Value rhs, bool is_signed = true)
                    throws TypeMismatchErr {
            Type.TID tidreq;
            OpCode   opcode;
            if (lhs.value_type.is_float) {
                tidreq = FLOAT_TYPE; is_signed = true;
                opcode = FREM;
            } else {
                tidreq = INT_TYPE;
                opcode = is_signed? OpCode.SREM: OpCode.UREM;
            }
            this.nocheck(opcode,
                checkop_same(lhs, rhs, tidreq, "BinarySSA::as_rem"),
                lhs, rhs, true);
        }
        public BinarySSA.as_logic(OpCode opcode, Value lhs, Value rhs)
                    throws TypeMismatchErr {
            if (!opcode.is_logic_op())
                crash_fmt("Requires logic opcode, but got %s", opcode.get_name());
            IntType lty = value_int_or_throw(lhs, "BinarySSA::as_logic().lhs");
            IntType rty = value_int_or_throw(rhs, "BinarySSA::as_logic().rhs");
            if (!opcode.is_shift_op())
                type_match_or_throw(lty, rty);
            this.nocheck(opcode, lty, lhs, rhs, opcode == ASHR);
        }
        public BinarySSA.as_and (Value lhs, Value rhs) throws TypeMismatchErr { this.as_logic(AND,  lhs, rhs); }
        public BinarySSA.as_orr (Value lhs, Value rhs) throws TypeMismatchErr { this.as_logic(ORR,  lhs, rhs); }
        public BinarySSA.as_xor (Value lhs, Value rhs) throws TypeMismatchErr { this.as_logic(XOR,  lhs, rhs); }
        public BinarySSA.as_shl (Value lhs, Value rhs) throws TypeMismatchErr { this.as_logic(SHL,  lhs, rhs); }
        public BinarySSA.as_lshr(Value lhs, Value rhs) throws TypeMismatchErr { this.as_logic(LSHR, lhs, rhs); }
        public BinarySSA.as_ashr(Value lhs, Value rhs) throws TypeMismatchErr { this.as_logic(ASHR, lhs, rhs); }

        class construct { _istype[TID.BINARY_SSA] = true; }

        private static Type checkop_same(IR.Value lhs, IR.Value rhs, Type.TID tid, string msg)
                    throws TypeMismatchErr {
            return type_match_istid(lhs.value_type, rhs.value_type, tid, msg);
        }
    }

    /** BinarySSA 的左操作数. */
    private sealed class BinaryLHSUse: Use {
        public new BinarySSA user {
            get { return static_cast<BinarySSA>(_user); }
        }
        public override Value? usee {
            get { return user.lhs; } set { user.lhs = value; }
        }
        public BinaryLHSUse(BinarySSA user) { base.C1(user); }
    }

    /** BinarySSA 的右操作数. */
    private sealed class BinaryRHSUse: Use {
        public new BinarySSA user {
            get { return static_cast<BinarySSA>(_user); }
        }
        public override Value? usee {
            get { return user.rhs; } set { user.rhs = value; }
        }
        public BinaryRHSUse(BinarySSA user) { base.C1(user); }
    }
}
