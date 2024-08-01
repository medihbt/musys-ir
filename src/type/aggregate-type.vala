namespace Musys {
    public abstract class AggregateType: Type {
        public abstract Type   get_element_type_at(size_t index = 0);
        public abstract size_t element_number {get;}

        public bool  always_has_same_type {
            get { return _always_contain_same_type; }
        }
        public virtual bool has_same_type {
            get { return always_has_same_type; }
        }

        protected class stdc.bool _always_contain_same_type = true;
        protected string _name;
        protected size_t _hash_cache;

        protected AggregateType.C1(TypeContext tctx, TID tid) {
            base.C1(tid, tctx);
            _hash_cache = 0;
        }
        class construct { _istype[TID.AGGR_TYPE] = true; }
    }

    public sealed class ArrayType: AggregateType {
        public override size_t hash()
        {
            if (_hash_cache != 0)
                return _hash_cache;
            _hash_cache = MakeHash(_element_type, _element_number);
            return _hash_cache;
        }

        public override size_t instance_align {
            get { return element_type.instance_align; }
        }
        public override size_t instance_size { get { return 0; } }
        public override string name {
            get {
                if (_name == null)
                    _name = @"[ $element_number x $element_type ]";
                return _name;
            }
        }

        public Type element_type{get;}

        public override Type get_element_type_at(size_t index) {
            return element_type;
        }

        public override size_t element_number{ get { return _element_number; } }

        protected override bool _relatively_equals(Type rhs)
        {
            if (!rhs.is_array)
                return false;
            var arhs = (ArrayType)rhs;
            return arhs._element_number == _element_number &&
                   arhs._element_type.equals(_element_type);
        }
        protected size_t _element_number;

        public ArrayType(TypeContext tctx, Type elem_type, size_t elem_number)
        {
            base.C1(tctx, TID.ARRAY_TYPE);
            this._element_type   = elem_type;
            this._element_number = elem_number;
        }
        class construct { _istype[TID.ARRAY_TYPE] = true; }

        [CCode (cname="Musys_ArrayType_MakeHash")]
        public static size_t MakeHash(Type elemty, size_t elem_number) {
            return hash_combine3(_TID_HASH[TID.ARRAY_TYPE],
                                 elemty.hash(), elem_number);
        }
    }

    //  public sealed class VectorType: Aggrega
}
