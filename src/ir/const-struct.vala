public class Musys.IR.StructExpr: ConstExpr {
    public StructType struct_type {
        get { return static_cast<StructType>(value_type); }
    }
    public size_t nelems { get { return struct_type.nfields; } }
    internal Constant[]? _elems;
    private void _init_elems()
    {
        try {
            _elems = new Constant[struct_type.nfields];
            for (int i = 0; i < _elems.length; i++)
                _elems[i] = Constant.CreateZero(struct_type.fields[i]);
        } catch (TypeMismatchErr e) {
            crash_err(e, "at " + Log.METHOD);
        }
    }
    public Constant[] elems {
        get {
            if (_elems == null)
                _init_elems();
            return (!)_elems;
        }
    }
    public Constant[]? nullable_elems { get { return _elems; } }

    public Constant? get_elem(int index)
    {
        if (index < 0 || index >= nelems)
            return null;
        return elems[index];
    }
    public void set_elem(int index, Constant value)
                throws TypeMismatchErr, RuntimeErr {
        if (index < 0 || index >= nelems)
            throw new RuntimeErr.INDEX_OVERFLOW("Requires [0, %lu), got %d", nelems, index);
        if (_elems == null && value.is_zero)
            return;
        unowned var elems = this.elems;
        if (elems[index] == value)
            return;
        if (struct_type.fields[index].equals(value.value_type)) {
            elems[index] = value;
            return;
        }
        throw new TypeMismatchErr.MISMATCH(
            "StructExpr(%p)[%d] requires %s, but got %s",
            this, index,
            struct_type.fields[index].to_string(),
            value.value_type.to_string()
        );
    }

    public override bool is_zero {
        get {
            if (_elems == null)
                return true;
            foreach (Constant? c in _elems) {
                if (c != null && !c.is_zero)
                    return false;
            }
            return true;
        }
    }
    public override void accept(IValueVisitor visitor) {
        visitor.visit_struct_expr(this);
    }
    public StructExpr.empty(StructType sty) {
        base.C1(STRUCT_EXPR, sty);
    }
    class construct {
        _istype[TID.STRUCT_EXPR] = true;
    }
}
