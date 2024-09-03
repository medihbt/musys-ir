public class Musys.StructType: AggregateType {
    /** 结构体的分类. 不同类型的结构体各不相同,  */
    public enum Kind {
        /** 匿名结构体: 只有字段表示, 没有名称. 与其他结构体比较时
         *  只比较字段成员. */
        ANOMYMOUS,

        /** 带标签结构体: 既有字段表示, 也有名称. 与其他结构体比较
         *  时既比较字段成员, 也比较名称成员. */
        SYMBOLLED,

        /** 不透明结构体: 只有名称，没有字段. 比较时只比较名称. */
        OPAQUE;

        public bool has_name() {
            return this == SYMBOLLED || this == OPAQUE;
        }
        public bool has_field() {
            return this == SYMBOLLED || this == ANOMYMOUS;
        }
    }

    /**
     * 结构体的分类. 不同类型的结构体各不相同.  
     * @see Kind
     */
    public Kind kind { get; internal set; }

    /**
     * 结构体的字段表. 当 `fields == null` 时表示它是一个**不透明结构体**.
     * 
     * @see is_opaque
     *
     * @see _fields
     */
    public Type[]? fields { get; internal set; }

    /**
     * 表示该结构体是不是**不透明的**.
     * 一个不透明结构体的内部字段成员全部不可见, 不能使用 getelementptr 之类
     * 的指令获取成员指针. */
    public bool is_opaque {
        get { return kind == OPAQUE || _fields == null; }
    }

    /** 结构体字段的数量. 不透明结构体的字段数量是 0. */
    public size_t nfields { get { return _fields.length; } }

    /**
     * {@inheritDoc}
     */
    public override Type get_element_type_at(size_t index) {
        return index >= _fields.length? type_ctx.void_type: _fields[index];
    }
    /**
     * {@inheritDoc}
     */
    public override size_t element_number { get { return nfields; } }

    public override size_t hash() {
        if (_hash_cache == 0)
            _hash_cache = MakeHash(kind, name, fields);
        return _hash_cache;
    }
    protected override bool _relatively_equals(Type rhs)
    {
        if (!rhs.is_struct)
            return false;
        var srhs = static_cast<StructType>(rhs);
        if (kind.has_name()  && !_equal_by_name(this, srhs))
            return false;
        if (kind.has_field() && !_equal_by_content(this, srhs))
            return false;
        return true;
    }

    /**
     * {@inheritDoc}
     */
    public override size_t instance_size {
        get {
            if (is_opaque)
                return 0;
            if (_instance_size == 0)
                _update_size_align();
            return _instance_size;
        }
    }
    /**
     * {@inheritDoc}
     */
    public override size_t instance_align {
        get {
            if (is_opaque)
                return 0;
            if (_instance_align == 0)
                _update_size_align();
            return _instance_align;
        }
    }
    private size_t _instance_size  = 0;
    private size_t _instance_align = 0;
    private void _update_size_align()
    {
        size_t isize = 0, align = 0, cnt = 0;
        foreach (Type? type in fields) {
            if (unlikely(type == null)) {
                crash_fmt({Log.FILE, Log.METHOD, Log.LINE},
                    "StructType(name %s) index %lu NOT Initialized",
                    symbol_name, cnt
                );
            }
            isize = StructType._update_size(isize, type);
            align = size_t.max(align, type.instance_align);
            cnt++;
        }
        _instance_align = align;
        _instance_size = fill_to(isize, align);
    }

    public override string name { get { return _name; } }
    public string?  symbol_name {
        get { return _name; }
        set {
            if (value == null) {
                _name = null;
                _kind = ANOMYMOUS;
                return;
            }
            if (value[0] == '%')
                _name = value;
            _name = "%" + value;
        }
    }
    private string _typestr_cache = null;
    public override unowned string to_string()
    {
        if (_name != null)
            return _name;
        if (_typestr_cache == null) {
            unowned Type[] fields = this.fields;
            var nameb = new StringBuilder("{ ");
            for (uint index = 0; index <= fields.length; index++) {
                if (index != 0)
                    nameb.append_c(',');
                nameb.append(fields[index].to_string());
            }
            nameb.append_c('}');
            _typestr_cache = nameb.free_and_steal();
        }
        return _typestr_cache;
    }

    private int8 _element_consist = 0;
    public override bool element_consist {
        get {
            if (is_opaque)
                return false;
            if (_element_consist == 0) {
                unowned Type ty0 = _fields[0];
                foreach (unowned Type ty in fields) {
                    if (ty.equals(ty0))
                        continue;
                    _element_consist = -1;
                    return false;
                }
                _element_consist = 1;
                return true;
            }
            return _element_consist == 1;
        }
    }

    public StructType.anomymous(TypeContext tctx, size_t nfields) {
        base.C1(tctx, STRUCT_TYPE);
        this._fields = new Type[nfields];
        this._kind   = ANOMYMOUS;
    }
    public StructType.anomymous_copy(TypeContext tctx, Type[] fields) {
        base.C1(tctx, STRUCT_TYPE);
        this._fields = fields.copy();
        _update_size_align();
        this._kind = ANOMYMOUS;
    }
    public StructType.anomymous_move(TypeContext tctx, owned Type[] fields) {
        base.C1(tctx, STRUCT_TYPE);
        this._fields = (owned)fields;
        _update_size_align();
        this._kind = ANOMYMOUS;
    }

    public StructType.symbolled(TypeContext tctx, size_t nfields, string name) {
        base.C1(tctx, STRUCT_TYPE);
        this._fields = new Type[nfields];
        this.symbol_name = name;
        this._kind = SYMBOLLED;
    }
    public StructType.symbolled_copy(TypeContext tctx, Type[] fields, string name) {
        base.C1(tctx, STRUCT_TYPE);
        this._fields = fields.copy();
        this.symbol_name = name;
        _update_size_align();
        this._kind = SYMBOLLED;
    }
    public StructType.symbolled_move(TypeContext tctx, owned Type[] fields, string name) {
        base.C1(tctx, STRUCT_TYPE);
        this._fields = (owned)fields;
        this.symbol_name = name;
        _update_size_align();
        this._kind = SYMBOLLED;
    }

    public StructType.opaque(TypeContext tctx, string name) {
        base.C1(tctx, STRUCT_TYPE);
        this.symbol_name = name;
        this._kind = OPAQUE;
    }

    class construct {
        _istype[TID.STRUCT_TYPE]     = true;
        _element_type_always_consist = false;
    }

    [CCode(cname="_ZN5Musys10StructType8MakeHashE")]
    public static size_t MakeHash(Kind kind, string? name, Type[]? fields)
    {
        size_t ret = hash_combine2(TID.STRUCT_TYPE, kind);
        if (kind.has_name()) {
            if (unlikely(name == null))
                crash(@"Struct name connot be null while kind is $kind");
            ret = hash_combine2(ret, name.hash());
        }
        if (kind.has_field()) {
            if (unlikely(fields == null))
                crash(@"Struct fields connot be null while kind is $kind");
            foreach (unowned Type ty in fields)
                ret = hash_combine2(ret, ty.hash());
        }
        return ret;
    }
    [CCode(cname="_ZN5Musys10StructType17MakeAnomymousHashE")]
    public static size_t MakeAnomymousHash(Type[] fields)
    {
        size_t ret = hash_combine2(TID.STRUCT_TYPE, Kind.ANOMYMOUS);
        foreach (unowned Type ty in fields)
            ret = hash_combine2(ret, ty.hash());
        return ret;
    }

    private static size_t _update_size(size_t prev_size, Type type)
    {
        size_t align = type.instance_align;
        size_t size  = type.instance_size;
        prev_size = fill_to(prev_size, align);
        return prev_size + size;
    }
    private static bool _equal_by_name(StructType lhs, StructType rhs) {
        return lhs.symbol_name == rhs.symbol_name;
    }
    private static bool _equal_by_content(StructType lhs, StructType rhs) {
        if (lhs.is_opaque || rhs.is_opaque)
            return false;
        unowned Type[] lhs_elems = lhs._fields;
        unowned Type[] rhs_elems = rhs._fields;
        if (lhs_elems.length != rhs_elems.length)
            return false;
        return Memory.cmp(lhs_elems, rhs_elems, lhs_elems.length * sizeof(Type)) == 0;
    }
}
