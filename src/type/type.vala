namespace Musys {
    /** 表示大小的整数值出现了错误 */
    public errordomain SizeErr {
        /** 大小不是 2 的次方. */
        NOT_PWR_OF_2;
    }

    /**
     * Musys IR 数值和 Musys MIR 寄存器的类型. 包括数值、集合、函数、指针等等。
     *
     * Musys 类型类的所有子类都必须在此软件包内, 外部代码不允许继承 Type 类或者
     * 其子类.
     *
     * 每个 Musys 类型对象都要注册在一个叫“类型上下文(`TypeContext`)”的对象中,
     * 以保证类型对象实例的唯一性. 因此, 在大多数情况下, 除非特殊说明, 你不能直接
     * new 一个类型对象然后使用之. 你需要通过 TypeContext 特定的方法获取这些类型.
     *
     * 类型都是''不可变的''. 一个类型对象一旦完成构造、注册在类型上下文中, 你就
     * 不允许写它的各种属性. 为了保证灵活性, Musys 没有提供关于不可变性的检查工具,
     * 因此, 倘若你修改了某个类型对象的信息, 系统可能不会报错, 但会产生一些难以
     * 预料的后果.
     */
    public abstract class Type {
        /**
         * TID 枚举, 每个类型类都对应一个枚举值.
         * @see tid
         */
        public enum TID {
            TYPE,       VOID_TYPE,
            VALUE_TYPE, INT_TYPE,   FLOAT_TYPE,
            AGGR_TYPE,  ARRAY_TYPE, VEC_TYPE, STRUCT_TYPE,
            REF_TYPE,   PTR_TYPE,   LABEL_TYPE,
            FUNCTION_TYPE,
            COUNT;
        } // enum TID

        /**
         * @see Musys.Type.TID
         */
        public TID tid{get; protected set;}

        /**
         * 该类型所属的类型上下文. 当一个类型与其他类型发生关联时(例如, 此类型是一个数组,
         * 被关联的那个类型是此类型的元素), 这几个类型的类型上下文需要全部相等.
         */
        public unowned TypeContext type_ctx{get;set;}

        protected class stdc.bool _istype[TID.COUNT] = {true, false};
        protected class stdc.bool _is_instantaneous  = true;
        protected const uint8 _TID_HASH[32] = {
            2,  3,  5,  7,  11, 13, 17, 19,
            23, 29, 31, 37, 41, 43, 47, 53,
            59, 61, 67, 71, 73, 79, 83, 89,
            97, 101,103,107,109,113,127,131
        };

        /** 这个类型对象是否是 TID 所属的类型类的对象. */
        public bool istype_by_id(TID tid) {
            return this._tid == tid || _istype[tid];
        }
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

        /**
         * 表示类型实例的大小.  
         * Represents the instance of this type.
         *
         * 倘若该类型不可实例化, 则大小为 0. 反之不成立.  
         * If instance size is 0, the type cannot be instantiated.
         * However, the converse is not true.
         */
        public abstract size_t instance_size{get;}

        /** 
         * 表示该类型是否可实例化.
         * Shows whether this type can make `Value` instances.
         */
        public virtual bool is_instantaneous {
            get { return instance_size > 0; }
        }

        /** 表示该类型的内存对齐字节大小. */
        public abstract size_t instance_align{get;}

        /** 类型的哈希值, 用于 TypeContext 验证类型的唯一性. */
        public abstract size_t hash();

        /** 类型判等, 用于 TypeContext 验证类型的唯一性. */
        public bool equals(Type rhs) {
            return this == rhs || _relatively_equals(rhs);
        }
        protected abstract bool _relatively_equals(Type rhs);

        /**
         * 类型的名称.
         * - 对于一般的类型, 名称就是与这种类型等价的字符串形式.
         * - 对于可以自定义名称标识符的类型 (如不匿名的结构体), 名称就是这个类型的标识符.
         */
        public abstract unowned string name{get;}

        /** 返回该类型对应的字符串形式. 你可以理解成“名称”. */
        public virtual  unowned string to_string() {
            return name;
        }

        protected Type.C1(TID tid, TypeContext type_ctx) {
            this._tid      = tid;
            this._type_ctx = type_ctx;
        }
        class construct { _istype[TID.TYPE] = true; }

        /**
         * 检查整数 size 是不是 2 的次方。倘若不是, 就抛 SizeErr 异常。
         *
         * @throws SizeErr
         */
        public static void CheckPowerOf2(size_t size)
                           throws SizeErr {
            if (is_power_of_2(size))
                return;
            throw new SizeErr.NOT_PWR_OF_2("align %lu", size);
        }


        /**
         * 检查类型数组 lhs 和 rhs 在区间 [0, n) 之间是否相等.
         */
        public static bool array_nequals(
                            [CCode (array_length = false)]Type[] lhs,
                            [CCode (array_length = false)]Type[] rhs,
                            size_t n)
        {
            for (size_t i = 0; i < n; i++) {
                if (!lhs[i].equals(rhs[i]))
                    return false;
            }
            return true;
        }

        public static bool array_nequals_full(
                            [CCode (array_length = false)]Type[] lhs,
                            [CCode (array_length = false)]Type[] rhs,
                            size_t n) {
            return lhs == rhs ||
                Memory.cmp(lhs, rhs, n * sizeof(pointer)) == 0;
        }
    } // class Type

    /**
     * 空类型, `null` 的占位符. 一般情况下, VoidType 不允许产生值或者寄存器实例.
     *
     * 想通过 TypeContext 创建一个 VoidType 实例, 你需要读取 `TypeContext.void_type` 属性.
     *
     * @see Musys.Type
     */
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

    [CCode(cname="_ZN5Musys9type_hashE")]
    public uint type_hash(Type type) {
        return (uint)type.hash();
    }

    [CCode(cname="_ZN5Musys10type_equalE")]
    public bool type_equal(Type l, Type r) {
        return l.equals(r);
    }
}
