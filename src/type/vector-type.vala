public class Musys.VectorType: AggregateType {
    public unowned Type element_type { get; internal set; }
    private size_t _length;
    public  size_t  length {
        get { return _length; }
        internal set {
            if (is_power_of_2(value))
                _length = value;
            crash_fmt(
                "VectorType(%p) length requires power of 2, but got %lu",
                this, value
            );
        }
    }
    public bool is_scalable { get { return length == 0; } }

    public override Type get_element_type_at(size_t index) {
        return element_type;
    }
    public override size_t element_number { get { return length; } }

    public override size_t hash()
    {
        if (_hash_cache == 0)
            _hash_cache = MakeHash(element_type, length);
        return _hash_cache;
    }
    protected override bool _relatively_equals(Type rhs)
    {
        if (rhs.tid != VEC_TYPE)
            return false;
        unowned var vrhs = static_cast<VectorType>(rhs);
        return vrhs.length == length &&
               element_type.equals(vrhs.element_type);
    }
    public override size_t instance_size {
        get { return fill_to(
                element_type.instance_size * element_number,
                element_type.instance_align
        ); }
    }
    public override size_t instance_align {
        get { return instance_size; }
    }
    public override bool is_instantaneous { get { return true; } }
    public override string name {
        get {
            if (_name == null) {
                _name = is_scalable? @"<vscale x $element_type>"
                                   : @"<$length x $element_type>";
            }
            return _name;
        }
    }

    public VectorType.fixed(Type element, size_t length) {
        base.C1(element.type_ctx, VEC_TYPE);
        if (!is_power_of_2_nonzero(length)) {
            crash_fmt(
                "fixed VectorType %p requires length power of 2 and nonzero, but got %lu\n",
                this, length
            );
        }
        this.length       = length;
        this.element_type = element;
    }

    class construct { _istype[TID.VEC_TYPE] = true; }

    [CCode (cname="_ZN5Musys10VectorType8MakeHashE")]
    public static size_t MakeHash(Type element, size_t length) {
        return hash_combine3(_TID_HASH[TID.VEC_TYPE], element.hash(), length);
    }
}
