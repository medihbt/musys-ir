namespace Musys.IR {
    public class CompareSSA: Instruction {
        private Value _lhs;
        private Value _rhs;
        private unowned Use  _ulhs;
        private unowned Use  _urhs;
        private unowned Type _op_type;
        public  Value lhs {
            get { return _lhs; }
            set { set_usee_type_match(_op_type, ref _lhs, value, _ulhs); }
        }
        public  Value rhs {
            get { return _rhs; }
            set { set_usee_type_match(_op_type, ref _rhs, value, _urhs); }
        }
        public  Type operand_type { get { return _op_type; } }
        [CCode(notify=false)]
        public Condition condition { get; set; }

        public override void on_parent_finalize()
        {
            value_deep_clean(ref _lhs, _ulhs);
            value_deep_clean(ref _rhs, _urhs);
            base._deep_clean();
        }
        public override void on_function_finalize()
        {
            value_fast_clean(ref _lhs, _ulhs);
            value_fast_clean(ref _rhs, _urhs);
            base._fast_clean();
        }
        public override void accept(IValueVisitor visitor) {
            visitor.visit_inst_compare(this);
        }
        public CompareSSA.raw(OpCode opcode, Type operand_type, Condition cond) {
            base.C1(COMPARE_SSA, opcode, get_bool_type(operand_type));
            this._ulhs = new LHSUse().attach_back(this);
            this._urhs = new RHSUse().attach_back(this);
            this._condition = cond;
            this._op_type   = operand_type;
        }
        public CompareSSA.as_icmp(Value lhs, Value rhs, Condition cond)
                    throws TypeMismatchErr {
            Type ity = checkop_same(lhs, rhs, INT_TYPE, "CompareSSA::as_icmp");
            this.raw(ICMP, ity, cond.make_int());
            this.lhs = lhs; this.rhs = rhs;
        }
        public CompareSSA.as_fcmp(Value lhs, Value rhs, Condition cond)
                    throws TypeMismatchErr {
            Type fty = checkop_same(lhs, rhs, FLOAT_TYPE, "CompareSSA::as_fcmp");
            this.raw(FCMP, fty, cond.make_float());
            this.lhs = lhs; this.rhs = rhs;
        }
        class construct { _istype[TID.COMPARE_SSA] = true; }

        private class LHSUse: Use {
            public new CompareSSA user {
                get { return static_cast<CompareSSA> (_user); }
            }
            public override Value? usee {
                get { return user.lhs;  }
                set { user.lhs = value; }
            }
        }
        private class RHSUse: Use {
            public new CompareSSA user {
                get { return static_cast<CompareSSA> (_user); }
            }
            public override Value? usee {
                get { return user.rhs;  }
                set { user.rhs = value; }
            }
        }
        public enum Condition {
            FALSE = 0x00, TRUE = 0x07,
            LT = 0x01, EQ = 0x02, GT = 0x04,
            GE = 0x06, NE = 0x05, LE = 0x03,
            SIGNED_ORDERED = 0x08,
            IS_FLOAT       = 0x10,
            RESERVED_COUNT = 0x20;
            public bool is_lt() { return (this & LT) != 0; }
            public bool is_eq() { return (this & EQ) != 0; }
            public bool is_gt() { return (this & GT) != 0; }
            public bool is_signed_ordered() {
                return (this & SIGNED_ORDERED) != 0;
            }
            public bool is_signed() {
                return (this & SIGNED_ORDERED) != 0 && (this & IS_FLOAT) == 0;
            }
            public bool is_ordered() {
                return (this & SIGNED_ORDERED) != 0 && (this & IS_FLOAT) != 0;
            }
            public Condition make_int()   { return this & ~IS_FLOAT; }
            public Condition make_float() { return this | IS_FLOAT; }
            public Condition make_signed_ordered() {
                return this | SIGNED_ORDERED;
            }
            public Condition make_unsigned_unordered() {
                return this & ~SIGNED_ORDERED;
            }
            public unowned string to_string() {
                return _cmpssa_name_map[this];
            }
        }

        private static Type checkop_same(IR.Value lhs, IR.Value rhs, Type.TID tid, string msg)
                    throws TypeMismatchErr {
            return type_match_istid(lhs.value_type, rhs.value_type, tid, "%s", msg);
        }
    }

    [CCode(cname="_ZN5Musys2IR10CompareSSA9_name_mapE")]
    private unowned string _cmpssa_name_map[CompareSSA.Condition.RESERVED_COUNT] = {
        "false", "ult", "eq",  "ule", "ugt", "ne",  "uge", "true",
        "false", "slt", "eq",  "sle", "sgt", "ne",  "sge", "true",
        "false", "ult", "eq",  "ule", "ugt", "ne",  "uge", "true",
        "false", "olt", "eq",  "ole", "ogt", "ne",  "oge", "true",
    };
}
