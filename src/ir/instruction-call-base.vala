namespace Musys.IR {
    public abstract class CallBase: Instruction {
        [CCode(has_type_id=false)]
        public struct ArgInfo {
            Value       arg;
            unowned Use use;

            public void set_arg(Type type, Value? value) {
                User.set_usee_type_match(type, ref arg, value, use);
            }
        }
        internal ArgInfo []_args;
        public   ArgInfo []args { get { return _args; } }

        public unowned Value? get_arg(uint index)
                requires(index < _args.length) {
            return _args[index].arg;
        }
        public void set_arg(uint index, Value? value)
                requires(index < _args.length) {
            _args[index].set_arg(callee_fn_type.params[index], value);
        }
        public void clean_args() {
            for (uint i = 0; i < _args.length; i++) {
                unowned Value? arg = _args[i].arg;
                if (arg == null)
                    return;
                arg.remove_use_as_usee(_args[i].use);
                _args[i].arg = null;
            }
        }

        protected         Value       _callee;
        protected unowned PointerType _callee_type;
        protected unowned Use         _ucallee;
        public PointerType  callee_type    {
            get { return _callee_type; }
        }
        public FunctionType callee_fn_type {
            get { return static_cast<FunctionType>(_callee_type); }
        }

        public virtual Value callee {
            get { return _callee; }
            set { set_usee_type_match(_callee_type, ref _callee, value, _ucallee); }
        }
        public override void on_parent_finalize()
        {
            clean_args();
            callee       = null;
            _nodeof_this = null;
        }
        public override void on_function_finalize() {
            _callee = null;
            _nodeof_this = null;
        }

        protected CallBase.C1(Value.TID tid, OpCode opcode, PointerType fn_ptype) {
            unowned var ptarget = fn_ptype.target;
            if (!ptarget.is_function)
                crash(@"in CallBase::C1()::fn_type: requires function pointer, but got $ptarget");
            unowned var fn_type = static_cast<FunctionType>(ptarget);

            base.C1(tid, opcode, fn_type.return_type);
            this._callee_type = fn_ptype;
            var length = fn_type.params.length;
            this._ucallee = new CalleeUse().attach_back(this);
            this._args    = new ArgInfo[length];
            for (uint i = 0; i < length; i++)
                _args[i].use = new ArgUse(i).attach_back(this);
        }

        class construct { _istype[TID.CALL_BASE] = true; }

        [CCode(cname="_ZN5Musys2IR8CallBase9CalleeUseE")]
        private sealed class CalleeUse: Use {
            public inline new CallBase user {
                [CCode(cname="_ZN5Musys2IR8CallBase9CalleeUse4userEg")]
                get { return static_cast<CallBase>(_user); }
            }
            public override Value? usee {
                get { return user.callee; } set { user.callee = value; }
            }
        }
        [CCode(cname="_ZN5Musys2IR8CallBase6ArgUseE")]
        private sealed class ArgUse: Use {
            public uint index;
            public inline new CallBase user {
                [CCode(cname="_ZN5Musys2IR8CallBase6ArgUse4userEg")]
                get { return static_cast<CallBase>(_user); }
            }
            public override Value? usee {
                get { return user._args[index].arg; }
                set { user._args[index].set_arg(user.callee_fn_type.params[index], value); }
            }
            public ArgUse(uint index) { this.index = index; }
        }
    }
}
