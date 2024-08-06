namespace Musys {
    public abstract class RefType: Type {
        public Type target{ get { return _target; } }

        public override size_t instance_align {
            get { return type_ctx.machine_word_size; }
        }
        public override size_t instance_size {
            get { return type_ctx.machine_word_size; }
        }

        protected size_t _hash_cache;
        public override size_t hash() {
            if (_hash_cache == 0)
                _hash_cache = hash_combine2(_TID_HASH[tid], target.hash());
            return _hash_cache;
        }

        protected string _name;
        protected Type _target;
        protected RefType.C1(TypeContext tctx, TID tid, Type target) {
            base.C1(tid, tctx);
            this._target = target;
            this._name   = null;
        }
        class construct { _istype[TID.REF_TYPE] = true; }
    }

    public sealed class PointerType: RefType {
        public override string name {
            get {
                if (_name == null)
                    _name = @"$(_target)*";
                return _name;
            }
        }
        protected override bool _relatively_equals(Type rhs) {
            if (!rhs.is_pointer)
                return false;
            unowned var prhs = (PointerType)rhs;
            return prhs._target.equals(_target);
        }

        public PointerType(TypeContext tctx, Type target) {
            base.C1(tctx, TID.PTR_TYPE, target);
            _hash_cache = 0;
        }
        class construct { _istype[TID.PTR_TYPE] = true; }

        [CCode(cname="Musys_PtrType_MakeHash")]
        public static inline size_t MakeHash(Type target) {
            return hash_combine2(_TID_HASH[TID.PTR_TYPE], target.hash());
        }
    }

    public sealed class LabelType: RefType {
        protected override bool _relatively_equals(Type rhs) {
            return rhs.tid == TID.LABEL_TYPE &&
                   rhs.type_ctx == type_ctx;
        }
        public override string name { get { return "label"; } }

        public LabelType(TypeContext tctx)
        {
            base.C1(tctx, LABEL_TYPE, tctx.void_type);
        }
        class construct {
            _istype[TID.LABEL_TYPE] = true;
            _is_instantaneous       = false;
        }
    }
}
