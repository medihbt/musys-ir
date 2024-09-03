public class Musys.VectorType: AggregateType {
    public unowned Type element_type { get; internal set; }
    private size_t _length;
    public  size_t  length{
        get { return _length; }
        internal set {
            if (is_power_of_2(value))
                _length = value;
            crash_fmt({Log.FILE, Log.METHOD, Log.LINE},
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
    public override size_t hash() {
        return hash_combine3(tid, element_type.hash(), length);
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
    public override string name {
        get {
            if (_name == null) {
                _name = is_scalable? @"<vscale x $element_type>"
                                   : @"<$length x $element_type>";
            }
            return _name;
        }
    }
}
