namespace Musys.IR {
    public abstract class GlobalObject: Constant {
        public PointerType ptr_type {
            get { return static_cast<PointerType>(_value_type); }
        }
        public Type content_type { get { return ptr_type.target; } }

        public abstract bool is_extern {get;}
        public abstract bool is_mutable{get;set;}
        public abstract bool enable_impl ();
        public abstract bool disable_impl();

        protected bool _is_internal = false;
        public    bool  is_internal {
            get { return _is_internal;  }
            set { _is_internal = value; }
        }

        public override bool is_zero { get { return false; } }

        protected GlobalObject.C1(Value.TID tid, PointerType type, bool is_internal) {
            base.C1 (tid, type);
            this._is_internal = is_internal;
        }
        class construct {
            _istype[TID.GLOBAL_OBJECT] = true;
            _shares_ref               = false;
        }
    }
}