public errordomain Musys.TypeMismatchErr {
    MISMATCH, NOT_CHILD_OF,
    NOT_INSTANTANEOUS;
}

public class Musys.TypeContext: Object {
    protected enum InsertResult {
        OK, HAD_ITEM;
    }

    public   uint32 machine_word_size{ get; }
    private  TypeCtxCache _type_cache;
    internal Gee.HashMap<unowned Type, Type> _types;
    internal Gee.HashMap<string, StructType> _symbolled_struct_types;

    public IntType bool_type {
        get { return _type_cache.ity_bytes[0]; }
    }
    public VoidType void_type {
        get { return _type_cache.voidty; }
    }
    public LabelType label_type {
        get { return _type_cache.labelty; }
    }
    public IntType get_int_type(uint binary_bits) {
        return _type_cache.new_or_get_int_ty(binary_bits, this);
    }
    public FloatType ieee_f32 { get { return _type_cache.ieee_f32; } }
    public FloatType ieee_f64 { get { return _type_cache.ieee_f64; } }
    public ArrayType get_array_type(Type elemty, size_t len) {
        var ret = new ArrayType(this, elemty, len);
        return (ArrayType)get_or_register_type(ret);
    }
    public PointerType get_ptr_type(Type target) {
        var ret = new PointerType(this, target);
        return (PointerType)get_or_register_type(ret);
    }
    public FunctionType
    get_func_type(Type ret_ty, Type []?args_ty) throws TypeMismatchErr
    {
        foreach (unowned Type arg_ty in args_ty) {
            if (!arg_ty.is_instantaneous)
                throw new TypeMismatchErr.NOT_INSTANTANEOUS(arg_ty.to_string());
        }
        FunctionType fty = null;
        if (args_ty != null)
            fty = new FunctionType(ret_ty, args_ty);
        else
            fty = new FunctionType.move(ret_ty, new Type[0]);
        return (FunctionType)get_or_register_type(fty);
    }
    public FunctionType
    get_func_type_move(Type ret_ty, owned Type[] args_ty) throws TypeMismatchErr
    {
        foreach (unowned Type arg_ty in args_ty) {
            if (!arg_ty.is_instantaneous)
                throw new TypeMismatchErr.NOT_INSTANTANEOUS(arg_ty.to_string());
        }
        var fty = new FunctionType.move(ret_ty, (owned)args_ty);
        return (FunctionType)get_or_register_type(fty);
    }
    public StructType? get_struct_type_readonly(StructType type)
    {
        if (type.kind.has_name()) {
            unowned string name = type.symbol_name;
            if (_symbolled_struct_types.has_key(name))
                return _symbolled_struct_types[name];
            return null;
        }
        if (_types.has_key(type))
            return _types[type] as StructType;
        return null;
    }
    public StructType get_struct_type_or_add(StructType type)
    {
        /* 匿名结构体, 字段相同即类型相等 */
        if (type.kind == ANOMYMOUS) {
            if (!_types.has_key(type))
                return _types[type] as StructType;
            _types[type] = type;
            return type;
        }

        /* 具名结构体, 名称相同即类型相等 */
        unowned string name = type.symbol_name;
        unowned var sst = _symbolled_struct_types;
        if (!sst.has_key(name)) {
            sst[name] = type;
            return type;
        }
        StructType sty = sst[name];
        if (sty.is_opaque && !type.is_opaque) {
            sst[name] = type;
            return type;
        }
        return sty;
    }
    public StructType? get_named_struct_type(string name) {
        return _symbolled_struct_types[name];
    }
    public StructType get_reg_named_struct_type(string name, Type[]? fields)
    {
        if (_symbolled_struct_types.has_key(name))
            return _symbolled_struct_types[name];
        var ret = fields == null?
            new StructType.symbolled_copy(this, fields, name):
            new StructType.opaque(this, name);
        _symbolled_struct_types[name] = ret;
        return ret;
    }
    public VectorType get_vec_type(Type element_type, size_t length)
    {
        if (!is_power_of_2_nonzero(length)) {
            crash_fmt({Log.FILE, Log.METHOD, Log.LINE},
                "in TypeContext %p: fixed VectorType requires length" +
                " to be power of 2 and nonzero, but got %lu\n",
                this, length
            );
        }
        var vec_ty = new VectorType.fixed(element_type, length);
        if (!_types.has_key(vec_ty)) {
            _types[vec_ty] = vec_ty;
            return vec_ty;
        }
        return _types[vec_ty] as VectorType;
    }

    /** 用障眼法写的方法, 让代码好看一些罢了 */
    public bool has_type(Type ty) { return ty.type_ctx == this; }

    private Type get_or_register_type(Type ty)
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
        if (_types.has_key(ty))
            return _types[ty];
        _types[ty] = ty;
        return ty;
    }

    public TypeContext(uint word_size = (uint)sizeof(pointer))
    {
        this._machine_word_size = word_size;
        this._type_cache.init_reg_ty(this);
        this._types = new Gee.HashMap<unowned Type, Type>(
            type_hash, type_equal
        );
        this._symbolled_struct_types = new Gee.HashMap<string, StructType>(
            (Gee.HashDataFunc)str_hash,
            (Gee.EqualDataFunc)str_equal,
            null
        );
    }
    ~TypeContext() {
        foreach (var entry in _types) {
            if (entry.value is StructType) {
                var sty = static_cast<StructType>(entry.value);
                sty.fields = null;
            }
        }
        foreach (var entry in _symbolled_struct_types) {
            StructType sty = entry.value;
            sty.fields = null;
        }
    }

    [CCode (has_type_id=false)]
    private struct TypeCtxCache {
        Gee.TreeMap<uint, IntType> int_types;
        IntType   ity_bytes[9];
        VoidType  voidty;
        LabelType labelty;
        FloatType ieee_f32;
        FloatType ieee_f64;

        internal IntType new_or_get_int_ty(uint bits, TypeContext tctx)
        {
            if (bits == 1 && ity_bytes[0] == null) {
                var ret = new IntType(tctx, bits);
                ity_bytes[0] = ret;
                return ret;
            }
            if (bits % 8 == 0 && bits <= 64) {
                uint bytes = bits / 8;
                if (ity_bytes[bytes] == null) {
                    var ty = new IntType(tctx, bits);
                    ity_bytes[bytes] = ty;
                    return ty;
                }
                return ity_bytes[bytes];
            }
            if (int_types == null)
                int_types = new Gee.TreeMap<uint, IntType>();
            if (int_types.has_key(bits))
                return int_types[bits];
            var ty = new IntType(tctx, bits);
            int_types[bits] = ty;
            return ty;
        }
        internal void init_reg_ty(TypeContext tctx)
        {
            voidty   = new VoidType(tctx);
            labelty  = new LabelType(tctx);
            ieee_f32 = FloatType.CreateIeee32(tctx);
            ieee_f64 = FloatType.CreateIeee64(tctx);
            ity_bytes[0] = new IntType(tctx, 1);
            ity_bytes[1] = new IntType(tctx, 8);
            ity_bytes[2] = new IntType(tctx, 16);
            ity_bytes[3] = null;
            ity_bytes[4] = new IntType(tctx, 32);
            ity_bytes[5] = null; ity_bytes[6] = null; ity_bytes[7] = null;
            ity_bytes[8] = new IntType(tctx, 64);
            int_types = null;
        }
    }
} // class TypeContext
