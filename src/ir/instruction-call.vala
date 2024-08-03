namespace Musys.IR {
    public class CallSSA: CallBase {
        public inline Function fn_callee {
            get { return static_cast<Function>(_callee); }
            set {
                if (value == _callee)
                    return;
                set_usee_type_match(_callee_type, ref _callee, value, _ucallee);
            }
        }
        public override Value callee {
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
        public override void accept(IValueVisitor visitor) {
            visitor.visit_inst_call(this);
        }

        public CallSSA.raw(PointerType fn_ptype) {
            base.C1(CALL_SSA, CALL, fn_ptype);
        }
        public CallSSA.from(Function callee, Value []args) {
            base.C1(CALL_SSA, CALL, callee.ptr_type);
            var length = this.args.length;
            if (args.length != length)
                crash(@"type [$(callee.function_type)] requires $length params, but got $(args.length)");
            for (uint i = 0; i < length; i++) {
                Type type = callee_fn_type.params[i];
                this.args[i].set_arg(type, args[i]);
            }
        }
        class construct { _istype[TID.CALL_SSA] = true; }
    }
}
