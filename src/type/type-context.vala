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

    public IntType bool_type{
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
