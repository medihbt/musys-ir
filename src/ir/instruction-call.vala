namespace Musys.IR {
    public class CallSSA: CallBase {
        public inline Function fn_callee {
            get { return static_cast<Function>(_callee); }
            set { assert_not_reached(); }
        }

        protected Value _callee;
        public    Value  callee {
            get { return _callee; }
            set {
                if (value != null && value.isvalue_by_id(TID.FUNCTION)) {
                    unowned var value_klass = value.get_class();
                    unowned var name = value_klass.get_name();
                    crash(@"CallSSA.callee requires Function, but it's $name");
                }
                fn_callee = static_cast<Function>(value);
            }
        }
        public override string get_name_of_callee() {
            return fn_callee.name;
        }
        public override void accept(IValueVisitor visitor) {
            visitor.visit_inst_call(this);
        }

        public CallSSA.raw(FunctionType fn_type) {
            base.C1_fixed_args(CALL_SSA, CALL, fn_type);
        }
        public CallSSA.from(Function callee, Value []args) {
            base.C1_fixed_args(CALL_SSA, CALL, callee.function_type);
            var length = this.uargs.length;
            if (args.length != length)
                crash(@"type [$(callee.function_type)] requires $length params, but got $(args.length)");
            for (uint i = 0; i < length; i++) {
                this.uargs[i].set_arg(args[i]);
            }
        }
        class construct { _istype[TID.CALL_SSA] = true; }
    }
}
