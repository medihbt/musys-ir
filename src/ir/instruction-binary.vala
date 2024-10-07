namespace Musys.IR {
    /**
     * === 双操作数指令 ===
     *
     * 顾名思义. 双操作数指令要么是算术运算指令，要么是逻辑运算指令.
     *
     * ==== 操作数表 ====
     * - `[0] = lhs`: 左操作数
     * - `[1] = rhs`: 右操作数
     *
     * ==== 文本格式 ====
     * - 整数加/减/乘指令: `%<id> = <opcode> <nsw|nuw> <type> <lhs>, <rhs>`, 其中 opcode = add, sub, mul
     * - 其他算术指令: `%<id> = <opcode> <type> <lhs>, <rhs>`, 其中 opcode = fadd,...,frem;sdiv,udiv,srem,urem
     * - 其他指令: `%<id> = <opcode> <type> <lhs>, <type> <rhs>`, 其中 opcode = and,or,...,ashr
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
                    return;
                }
                value_int_or_crash(value, "at BinarySSA.rhs::set()");
                User.replace_use(_rhs, value, _urhs);
                _rhs = value;
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
        public BinarySSA.nocheck(OpCode opcode, Type type, Value lhs, Value rhs) {
            base.C1 (BINARY_SSA, opcode, type);
            _ulhs = new BinaryLHSUse(this).attach_back(this);
            _urhs = new BinaryRHSUse(this).attach_back(this);
            this._lhs = lhs;
            this._rhs = rhs;
            _lhs.add_use_as_usee(_ulhs);
            _rhs.add_use_as_usee(_urhs);
        }

        public BinarySSA.as_add(Value lhs, Value rhs, bool is_signed = true) {
            unowned var type = _valuetype_same_or_crash(lhs, rhs);
            var opcode = type.is_int? OpCode.ADD: OpCode.FADD;
            this.nocheck(opcode, type, lhs, rhs);
            this._is_signed = is_signed;
        }
        public BinarySSA.as_sub(Value lhs, Value rhs, bool is_signed = true) {
            unowned var type = _valuetype_same_or_crash(lhs, rhs);
            var opcode = type.is_int? OpCode.SUB: OpCode.FSUB;
            this.nocheck(opcode, type, lhs, rhs);
            this._is_signed = is_signed;
        }
        public BinarySSA.as_mul(Value lhs, Value rhs, bool is_signed = true) {
            unowned var type = _valuetype_same_or_crash(lhs, rhs);
            var opcode = type.is_int? OpCode.MUL: OpCode.FMUL;
            this.nocheck(opcode, type, lhs, rhs);
            this._is_signed = is_signed;
        }
        public BinarySSA.as_idiv(Value lhs, Value rhs, bool is_signed = true) {
            unowned var type = int_value_match_or_crash(lhs, rhs);
            var opcode = is_signed? OpCode.SDIV: OpCode.UDIV;
            this.nocheck(opcode, type, lhs, rhs);
            this._is_signed = is_signed;
        }
        public BinarySSA.as_fdiv(Value lhs, Value rhs) {
            unowned var type = _floattype_same_or_crash(lhs, rhs);
            this.nocheck(FDIV, type, lhs, rhs);
            this._is_signed = true;
        }
        public BinarySSA.as_irem(Value lhs, Value rhs, bool is_signed = true) {
            unowned var type = int_value_match_or_crash(lhs, rhs);
            var opcode = is_signed? OpCode.SREM: OpCode.UREM;
            this.nocheck(opcode, type, lhs, rhs);
            this._is_signed = is_signed;
        }
        public BinarySSA.as_frem(Value lhs, Value rhs) {
            unowned var type = _floattype_same_or_crash(lhs, rhs);
            this.nocheck(FREM, type, lhs, rhs);
            this._is_signed = true;
        }
        public inline BinarySSA.as_logic(OpCode opcode, Value lhs, Value rhs)
        {
            if (!opcode.is_logic_op())
                crash (@"Requires logic opcode, but got $(opcode)");
            unowned Type type = opcode.is_shift_op() ?
                                _all_int_or_crash(lhs, rhs):
                                int_value_match_or_crash(lhs, rhs);
            this.nocheck(opcode, type, lhs, rhs);
            this._is_signed = opcode == ASHR;
        }
        public BinarySSA.as_and (Value lhs, Value rhs) { this.as_logic(AND,  lhs, rhs); }
        public BinarySSA.as_orr (Value lhs, Value rhs) { this.as_logic(ORR,  lhs, rhs); }
        public BinarySSA.as_xor (Value lhs, Value rhs) { this.as_logic(XOR,  lhs, rhs); }
        public BinarySSA.as_shl (Value lhs, Value rhs) { this.as_logic(SHL,  lhs, rhs); }
        public BinarySSA.as_lshr(Value lhs, Value rhs) { this.as_logic(LSHR, lhs, rhs); }
        public BinarySSA.as_ashr(Value lhs, Value rhs) { this.as_logic(ASHR, lhs, rhs); }

        [CCode(cname="_ZN5Musys2IR9BinarySSA9CreateDivE")]
        public static BinarySSA CreateDiv(Value lhs, Value rhs, bool is_signed = true) {
            return lhs.value_type.is_int? new BinarySSA.as_idiv(lhs, rhs, is_signed):
                                          new BinarySSA.as_fdiv(lhs, rhs);
        }
        [CCode(cname="_ZN5Musys2IR9BinarySSA9CreateRemE")]
        public static BinarySSA CreateRem(Value lhs, Value rhs, bool is_signed = true) {
            return lhs.value_type.is_int? new BinarySSA.as_irem(lhs, rhs, is_signed):
                                          new BinarySSA.as_frem(lhs, rhs);
        }
        class construct { _istype[TID.BINARY_SSA] = true; }
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

    private unowned PrimitiveType _valuetype_same_or_crash(Value lhs, Value rhs)
    {
        unowned var lty = lhs.value_type;
        unowned var rty = rhs.value_type;
        if (!lty.is_valuetype || !rty.is_valuetype) {
            crash(@"Add instruction requires int/float value type, but:\nlhs is $(lty)\nrhs is $(rty)"
                  , true, {Log.FILE, Log.METHOD, Log.LINE});
        }
        if (!lty.equals(rty)) {
            crash(@"Add instruction requires LHS and RHS type be the same, but\nlhs is $(lty)\nrhs is $(rty)"
                  , true, {Log.FILE, Log.METHOD, Log.LINE});
        }
        return static_cast<PrimitiveType>(lty);
    }
    private unowned Type _all_int_or_crash(Value lhs, Value rhs)
    {
        unowned var lty = lhs.value_type;
        unowned var rty = rhs.value_type;
        if (!lty.is_int || !rty.is_int) {
            crash(@"requires int type, but:\nlhs is $(lty)\nrhs is $(rty)"
                  , true, {Log.FILE, Log.METHOD, Log.LINE});
        }
        return lty;
    }
    private unowned FloatType _floattype_same_or_crash(Value lhs, Value rhs)
    {
        unowned var lty = lhs.value_type;
        unowned var rty = rhs.value_type;
        if (!lty.is_float || !rty.is_float) {
            crash(@"requires float type, but:\nlhs is $(lty)\nrhs is $(rty)"
                  , true, {Log.FILE, Log.METHOD, Log.LINE});
        }
        if (!lty.equals(rty)) {
            crash(@"requires LHS and RHS type be the same, but:\nlhs is $(lty)\nrhs is $(rty)"
                  , true, {Log.FILE, Log.METHOD, Log.LINE});
        }
        return static_cast<FloatType>(lty);
    }
}
