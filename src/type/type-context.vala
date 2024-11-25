/**
 * **类型上下文** -- 存储、注册、获取类型对象, 保证类型唯一性的类
 *
 * 注意, 大多数类型类一般不直接通过 new 创建实例, 需要通过 `TypeContext`
 * 中转一下。
 *
 * @see Musys.Type
 */
public class Musys.TypeContext: Object {
    protected enum InsertResult {
        OK, HAD_ITEM;
    }

    public Platform target { get; internal set; }

    /** 目标机器字长, 单位是字节. Musys 只支持一字节 8 位的系统. */
    public uint32 word_size{ get { return target.word_size_bytes; } }

    /** Target pointer size in bytes. Musys only supports platforms 8 bits per byte. */
    public uint32 ptr_size { get { return target.ptr_size_bytes; } }

    /** 类型缓存. 这部分缓存可以加快整数等类型的存取. */
    private  TypeCtxCache _type_cache;
    internal HashTable<unowned Type, Type> _types;
    internal HashTable<string, StructType> _symbolled_structs;

    public IntType   bool_type  { get { return _type_cache.ity_bytes[0]; } }
    public VoidType  void_type  { get { return _type_cache.voidty;  } }
    public LabelType label_type { get { return _type_cache.labelty; } }
    public unowned IntType get_int_type(uint binary_bits) {
        return _type_cache.new_or_get_int_ty(binary_bits, this);
    }
    public unowned IntType intptr_type {
        get { return get_int_type(ptr_size * 8); }
    }
    public FloatType ieee_f32 { get { return _type_cache.ieee_f32; } }
    public FloatType ieee_f64 { get { return _type_cache.ieee_f64; } }

    /** 获取元素类型为 elemty, 长度为 len 的数组类型 */
    public unowned ArrayType get_array_type(Type elemty, size_t len) {
        var ret = new ArrayType(this, elemty, len);
        return (ArrayType)get_or_register_type(ret);
    }

    public PointerType opaque_ptr { get { return _type_cache.opaque_ptr_type; } }

    /**
     * 获取返回类型为 `ret_ty`, 参数类型为 `args_ty` 的函数类型.
     *
     * @param ret_ty 返回值类型.
     */
    public unowned FunctionType get_func_type(Type ret_ty, Type []?args_ty)
    {
        FunctionType fty = null;
        if (args_ty != null)
            fty = new FunctionType(ret_ty, args_ty);
        else
            fty = new FunctionType.move(ret_ty, new Type[0]);
        return (FunctionType)get_or_register_type(fty);
    }
    /**
     * 获取返回类型为 `ret_ty`, 参数类型为 `args_ty` 的函数类型. 该函数会夺取参数类型的所有权.
     *
     * @param ret_ty 返回值类型.
     */
    public unowned FunctionType get_func_type_move(Type ret_ty, owned Type[] args_ty)
    {
        var fty = new FunctionType.move(ret_ty, (owned)args_ty);
        return (FunctionType)get_or_register_type(fty);
    }

    public unowned StructType get_anomymous_struct_type(owned Type[] fields)
    {
        var sty = new StructType.anomymous_move((owned)fields);
        unowned Type? ret = _types.get(sty);
        if (ret != null)
            return static_cast<StructType>(ret);
        _types.insert(sty, sty);
        return static_cast<StructType>(_types[sty]);
    }
    public unowned StructType get_named_struct_type(string name, Type[]? fields)
    {
        unowned StructType? vty = _symbolled_structs[name];
        if (vty != null)
            return vty;
        var ret = fields != null?
            new StructType.symbolled_copy(fields, name):
            new StructType.opaque(this, name);
        _symbolled_structs[name] = (owned)ret;
        return _symbolled_structs[name];
    }
    public unowned VectorType get_vec_type(Type element_type, size_t length)
    {
        if (!is_power_of_2_nonzero(length)) {
            crash_fmt(
                "in TypeContext %p: fixed VectorType requires length" +
                " to be power of 2 and nonzero, but got %lu\n",
                this, length
            );
        }
        var vec_ty = new VectorType.fixed(element_type, length);
        return get_reg_vec_type(vec_ty);
    }
    public unowned VectorType get_reg_vec_type(VectorType vec_ty)
    {
        unowned Type vecvty = get_or_register_type(vec_ty);
        assert(vecvty.is_vector);
        return static_cast<VectorType>(vecvty);
    }

    /** 用障眼法写的方法, 让代码好看一些罢了 */
    public bool has_type(Type ty) { return ty.type_ctx == this; }

    private unowned Type get_or_register_type(Type ty)
    {
        if (ty.is_int)
            return _type_cache.new_or_get_int_ty(((IntType)ty).binary_bits, this);
        if (ty.is_float) {
            if (ty.equals(_type_cache.ieee_f32))
                return _type_cache.ieee_f32;
            return _type_cache.ieee_f64;
        }
        if (ty.is_void)
            return _type_cache.voidty;
        if (ty.is_label)
            return _type_cache.labelty;

        /* common types: in a large hash map. */
        unowned Type? vty = _types.get(ty);
        if (vty == null) {
            _types.set(ty, ty);
            vty = ty;
        }
        return vty;
    }

    public TypeContext(uint word_size = (uint)sizeof(pointer))
    {
        this.target = new Platform.host() {
            word_size_bytes = (uint8)word_size,
            ptr_size_bytes  = (uint8)word_size,
        };
        this._type_cache.init_reg_ty(this);
        this._types = new HashTable<unowned Type, Type>(type_hash, type_equal);
        this._symbolled_structs = new HashTable<string, StructType>(str_hash, str_equal);
    }

    ~TypeContext() {
        _types.foreach((k, v) => {
            if (k.istype_by_id(STRUCT_TYPE))
                static_cast<StructType>(k).fields = null;
        });
        _symbolled_structs.foreach((s, t) => t.fields = null);
    }

    [CCode (has_type_id=false)]
    private struct TypeCtxCache {
        //  Gee.TreeMap<uint, IntType> int_types;
        Tree<uint, IntType> int_types;
        IntType   ity_bytes[9];
        VoidType  voidty;
        LabelType labelty;
        FloatType ieee_f32;
        FloatType ieee_f64;
        PointerType opaque_ptr_type;

        internal unowned IntType new_or_get_int_ty(uint bits, TypeContext tctx)
        {
            if (bits == 1 && ity_bytes[0] == null) {
                ity_bytes[0] = new IntType(tctx, bits);
                return ity_bytes[0];
            }
            if (bits % 8 == 0 && bits <= 64) {
                uint bytes = bits / 8;
                if (ity_bytes[bytes] == null) {
                    ity_bytes[bytes] = new IntType(tctx, bits);
                    return ity_bytes[bytes];
                }
                return ity_bytes[bytes];
            }
            if (int_types == null)
                int_types = new Tree<uint, IntType>(uintcmp);
            unowned IntType? ret = int_types.lookup(bits);
            if (ret != null)
                return ret;
            int_types.insert(bits, new IntType(tctx, bits));
            return int_types.lookup(bits);
        }
        internal void init_reg_ty(TypeContext tctx)
        {
            voidty   = new VoidType(tctx);
            labelty  = new LabelType(tctx);
            opaque_ptr_type = new PointerType.opaque(tctx);
            ieee_f32 = new FloatType.ieee_fp32(tctx);
            ieee_f64 = new FloatType.ieee_fp64(tctx);
            ity_bytes[0] = new IntType(tctx, 1);
            ity_bytes[1] = new IntType(tctx, 8);
            ity_bytes[2] = new IntType(tctx, 16);
            ity_bytes[3] = null;
            ity_bytes[4] = new IntType(tctx, 32);
            ity_bytes[5] = null; ity_bytes[6] = null; ity_bytes[7] = null;
            ity_bytes[8] = new IntType(tctx, 64);
            int_types = null;
        }
    } // struct TypeCtxCache
} // class TypeContext
