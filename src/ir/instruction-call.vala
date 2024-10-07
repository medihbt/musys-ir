namespace Musys.IR {
    /**
     * === 静态函数调用指令 ===
     *
     * 调用函数 `fn_callee`. 要求 callee 必须是 `Function` 类型的.
     *
     * ''指令文本格式'':
     * - 有返回值: `%<id> = [tail] call <return type> <callee> ([<ty0> <arg0> [, <ty...> <arg...>]])`
     * - 无返回值: `[tail] call void <callee> ([<ty0> <arg0> [, <ty...> <arg...>]])`
     *
     * ''操作数表'': 同父类 `CallBase`.
     */
    public class CallSSA: CallBase {
        public Function fn_callee {
            get { return static_cast<Function>(_callee); }
            set { callee = value; }
        }
        public bool is_tail_call { get; set; default = false; }

        protected override void _check_callee(Value? callee) throws Error
        {
            if (callee == null || callee.isvalue_by_id(TID.FUNCTION))
                return;
            crash_fmt(SourceLocation.current(),
                "CallSSA callee should be global function (NOT anything dynamic)" +
                "while it receives value(%p) type %s",
                callee, callee.value_type.to_string());
        }
        public override void accept(IValueVisitor visitor) {
            visitor.visit_inst_call(this);
        }

        public CallSSA.raw(FunctionType fn_type) {
            base.C1(CALL_SSA, CALL, fn_type);
        }
        public CallSSA.with_args(Function callee, Gee.List<Value> args) {
            base.C1_with_args(CALL_SSA, CALL, callee.function_type, args);
        }
        class construct { _istype[TID.CALL_SSA] = true; }
    }

    /**
     * === 动态函数调用指令 ===
     *
     * 同父类 `CallBase`.
     *
     * ''指令文本格式'':
     * - 有返回值: `%<id> = dyncall <return type> <callee> ([<ty0> <arg0> [, <ty...> <arg...>]])`
     * - 无返回值: `dyncall void <callee> ([<ty0> <arg0> [, <ty...> <arg...>]])`
     *
     * ''操作数表'': 同父类 `CallBase`.
     */
    public class DynCallSSA: CallBase {
        public override void accept(IValueVisitor visitor) {
            visitor.visit_inst_dyn_call(this);
        }
        public DynCallSSA.raw(FunctionType fn_type) {
            base.C1(DYN_CALL_SSA, DYN_CALL, fn_type);
        }
        public DynCallSSA.with_args(FunctionType callee_type, Value callee, Gee.List<Value> args) {
            base.C1_with_args(DYN_CALL_SSA, DYN_CALL, callee_type, args);
            this.callee = callee;
        }
        public DynCallSSA.from_function(Function callee, Gee.List<Value> args) {
            this.with_args(callee.function_type, callee, args);
        }
        class construct { _istype[TID.DYN_CALL_SSA] = true; }
    }
}
