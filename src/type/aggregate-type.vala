namespace Musys {
    /** 集合类型: 存放元素、可以索引的类型. */
    public abstract class AggregateType: Type {
        /**
         * 获取集合类型第 index 个元素类型. 当范围超限时返回 void 类型.
         * @param index 要获取的元素在集合类型中的位置.
         */
        public abstract Type get_element_type_at(size_t index = 0);
        
        /** 集合元素个数 */
        public abstract size_t element_number {get;}

        /** 这个类型类的所有类型对象中, 元素类型都是相同的. */
        public bool  element_always_consist {
            get { return _element_type_always_consist; }
        }
        /** 这个类型对象中, 元素类型都是相同的. */
        public virtual bool element_consist {
            get { return element_always_consist; }
        }

        protected class stdc.bool _element_type_always_consist = true;
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
        
        public override size_t instance_align{ get; }
        public override size_t instance_size { get; }
        public override string name {
            get {
                if (_name == null)
                    _name = @"[ $element_number x $element_type ]";
                return _name;
            }
        }

        public unowned Type element_type{get;}

        public override Type get_element_type_at(size_t index) {
            return element_type;
        }

        public override size_t element_number{ get { return _element_number; } }

        protected override bool _relatively_equals(Type rhs)
        {
            if (rhs.tid != ARRAY_TYPE)
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
            this._instance_align = elem_type.instance_align;
            this._instance_size  = elem_type.instance_size * elem_number;
        }
        class construct { _istype[TID.ARRAY_TYPE] = true; }

        [CCode (cname="Musys_ArrayType_MakeHash")]
        public static size_t MakeHash(Type elemty, size_t elem_number) {
            return hash_combine3(_TID_HASH[TID.ARRAY_TYPE],
                                 elemty.hash(), elem_number);
        }
    }
}
