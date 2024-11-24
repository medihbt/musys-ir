namespace Musys {
    public abstract class RefType: Type {
        [Version(deprecated=true, deprecated_since="0.0.1", replacement="target_loadable_or_storable")]
        public unowned Type target{ get { return _target; } }

        public abstract bool target_loadable(Type target);
        public virtual  bool target_storable(Type target) {
            return target_loadable(target);
        }
        public bool target_loadable_or_storable(Type target) {
            return target_loadable(target) ||
                   target_storable(target);
        }

        public override size_t instance_align {
            get { return type_ctx.word_size; }
        }
        public override size_t instance_size {
            get { return type_ctx.word_size; }
        }

        protected size_t _hash_cache;
        public override size_t hash() {
            if (_hash_cache == 0)
                _hash_cache = hash_combine2(_TID_HASH[tid], target.hash());
            return _hash_cache;
        }

        protected unowned Type _target;
        protected RefType.C1(TypeContext tctx, TID tid, Type target) {
            base.C1(tid, tctx);
            this._target = target;
        }
        class construct { _istype[TID.REF_TYPE] = true; }
    }

    /**
     * 指针类型. 为了方便类型存储、类型比较等, Musys-IR 的指针都是不透明的.
     * 也就是说, 指针类型实例不存储具体的指向类型, 某个指针实例的具体目标类型
     * 要根据应用于它的指令确定.
     */
    public sealed class PointerType: RefType {
        protected override bool _relatively_equals(Type rhs) {
            return rhs.istype_by_id(TID.OPAQUE_PTR_TYPE);
        }
        public override bool target_loadable(Type target) {
            return IsLegalPointee(target);
        }
        public override string name { get { return "ptr"; } }

        public PointerType.opaque(TypeContext tctx)
        {
            base.C1(tctx, TID.OPAQUE_PTR_TYPE, tctx.void_type);
        }

        class construct {
            _istype[TID.OPAQUE_PTR_TYPE] = true;
        }

        public static bool IsLegalPointee(Type target) {
            TID tid = target.tid;
            return tid != VOID_TYPE && tid != LABEL_TYPE && tid != FUNCTION_TYPE;
        }
    }

    public sealed class LabelType: RefType {
        protected override bool _relatively_equals(Type rhs) {
            return rhs.tid == TID.LABEL_TYPE &&
                   rhs.type_ctx == type_ctx;
        }
        public override string name { get { return "label"; } }
        public override bool target_loadable(Type pointee_type) { return false; }

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
