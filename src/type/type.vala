using GLib;

namespace Musys {
    public abstract class Type {
        public enum TID {
            TYPE,       VOID_TYPE,
            VALUE_TYPE, INT_TYPE,   FLOAT_TYPE,
            AGGR_TYPE,  ARRAY_TYPE, VEC_TYPE, STRUCT_TYPE,
            REF_TYPE,   PTR_TYPE,   LABEL_TYPE,
            FUNCTION_TYPE,
            COUNT;
        } // enum TID
        public      TID         tid{get; protected set;}
        public weak TypeContext type_ctx{get;set;}

        protected class stdc.bool _istype[TID.COUNT] = {true, false};
        protected class stdc.bool _is_instantaneous  = true;
        protected const uint16 _TID_HASH[32] = {
            2,  3,  5,  7,  11, 13, 17, 19,
            23, 29, 31, 37, 41, 43, 47, 53,
            59, 61, 67, 71, 73, 79, 83, 89,
            97, 101,103,107,109,113,127,131
        };

        public bool istype(TID tid) { return _istype[tid]; }
        public bool is_void       { get { return _istype[TID.VOID_TYPE]; }  }

        public bool is_valuetype  { get { return _istype[TID.VALUE_TYPE]; } }
        public bool is_int        { get { return _istype[TID.INT_TYPE]; }   }
        public bool is_float      { get { return _istype[TID.FLOAT_TYPE];}  }

        public bool is_aggregate  { get { return _istype[TID.AGGR_TYPE]; }  }
        public bool is_array      { get { return _istype[TID.ARRAY_TYPE]; } }
        public bool is_vector     { get { return _istype[TID.VEC_TYPE]; }   }
        public bool is_struct     { get { return _istype[TID.STRUCT_TYPE];} }

        public bool is_ref        { get { return _istype[TID.REF_TYPE]; } }
        public bool is_pointer    { get { return _istype[TID.PTR_TYPE]; } }
        public bool is_label      { get { return _istype[TID.LABEL_TYPE]; } }

        public bool is_function   { get { return _istype[TID.FUNCTION_TYPE]; } }

        /** ### Property: `Instance Size`
         *
         * 表示类型实例的大小.  
         * Represents the instance of this type.
         *
         * 倘若该类型不可实例化, 则大小为 0. 反之不成立.  
         * If instance size is 0, the type cannot be instantiated.
         * However, the converse is not true. */
        public abstract size_t instance_size{get;}

        /** ### Property: `is_instantaneous`
         *
         * 表示该类型是否可实例化. Shows whether this type can make `Value` instances. */
        public bool is_instantaneous { get { return instance_size > 0; } }

        public abstract size_t instance_align{get;}

        public abstract size_t hash();
        public bool equals(Type rhs) {
            return this == rhs || _relatively_equals(rhs);
        }
        protected abstract bool _relatively_equals(Type rhs);

        public abstract unowned string name{get;}
        public unowned string to_string() { return name; }

        protected Type.C1(TID tid, TypeContext type_ctx) {
            this._tid      = tid;
            this._type_ctx = type_ctx;
        }
    } // class Type

    public sealed class VoidType: Type {
        public VoidType(TypeContext tctx) {
            base.C1(TID.VOID_TYPE, tctx);
        }
        class construct {
            _istype[TID.VOID_TYPE] = true;
            _is_instantaneous     = false;
        }

        public override size_t instance_size  { get { return 0; } }

        public override size_t instance_align { get { return 0; } }

        public override unowned string name   { get { return "void"; } }

        public override size_t hash() { return _TID_HASH[TID.VOID_TYPE]; }

        protected override bool _relatively_equals(Type rhs) { return false; }
    }
}