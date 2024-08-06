namespace Musys {
    private inline size_t bit_to_byte(size_t bit) {
        return bit / 8 + (size_t)(bit % 8 != 0);
    }
    private inline size_t size_get_align(size_t bytes) {
        if (bytes >= 8)      return 8;
        else if (bytes >  4) return 8;
        else if (bytes >  2) return 4;
        else if (bytes == 2) return 2;
        else if (bytes == 1) return 1;
        else                 return 0;
    }

    public abstract class ValueType: Type {
        protected uint32 _binary_bits;
        public    uint32  binary_bits{get { return _binary_bits; }}

        public override size_t instance_size {
            get { return bit_to_byte(_binary_bits); }
        }
        public override size_t instance_align {
            get { return size_get_align(instance_size); }
        }

        protected string _name = null;

        protected ValueType.C1(TypeContext tctx, TID tid, uint32 binary_bits)
        {
            base.C1(tid, tctx);
            this._binary_bits = binary_bits;
        }
        class construct {
            _istype[TID.VALUE_TYPE] = true;
        }
    }

    public sealed class IntType: ValueType {
        public override string name {
            get {
                if (_name == null)
                    _name = @"i$(_binary_bits)";
                return _name;
            }
        }
        public override size_t hash() {
            return _TID_HASH[TID.INT_TYPE] + _binary_bits * 257;
        }
        protected override bool _relatively_equals(Type rhs) {
            if (!rhs.is_int)
                return false;
            return ((IntType)rhs)._binary_bits == binary_bits;
        }

        public IntType(TypeContext tctx, uint32 binary_bits) {
            base.C1(tctx, TID.INT_TYPE, binary_bits);
        }
        class construct { _istype[TID.INT_TYPE] = true; }
    }

    public sealed class FloatType: ValueType {
        public override size_t hash() {
            uint32 uid = ((uint32)_is_signed << 31) |
                         (_index_bits << 16) | (_tail_bits);
            return hash_combine2(_TID_HASH[TID.FLOAT_TYPE], uid);
        }

        public override string name {
            get {
                if (_name == null) {
                    char buff[16];
                    _name = @"f$(Fmt.u32base10(&buff[0], 16, (uint32)_binary_bits))";
                } return _name;
            }
        }
        protected override bool _relatively_equals(Type rhs)
        {
            if (!rhs.is_float)
                return false;
            var frhs = (FloatType)rhs;
            return frhs._tail_bits == _tail_bits  &&
                   frhs._index_bits== _index_bits &&
                   frhs._is_signed == _is_signed  &&
                   frhs._name      == _name;
        }

        public bool   is_signed {get;}
        public uint16 index_bits{get;}
        public uint16 tail_bits {get;}

        public FloatType(TypeContext tctx,  string name,
                         uint16 index_bits, uint16 tail_bits, bool is_signed = true)
        {
            base.C1(tctx, TID.FLOAT_TYPE,
                    (uint)is_signed + index_bits + tail_bits);
            this._name        = name;
            this._index_bits  = index_bits;
            this._tail_bits   = tail_bits;
            this._is_signed   = is_signed;
        }
        class construct { _istype[TID.FLOAT_TYPE] = true; }

        [CCode (cname="Musys_FloatType_CreateIeee32")]
        public static FloatType CreateIeee32(TypeContext tctx) {
            return new FloatType(tctx, "float",
                                 8, 23, true);
        }
        [CCode (cname="Musys_FloatType_CreateIeee64")]
        public static FloatType CreateIeee64(TypeContext tctx) {
            return new FloatType(tctx, "double",
                                 11, 52, true);
        }
    }
}