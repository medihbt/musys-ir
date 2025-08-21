namespace MusysIR {
    public unowned ValType type_index(ValType type, Value? index) throws TypeMismatchErr, RuntimeErr
    {
        if (type.is_pointer)
            return static_cast<PointerType>(type).target;
        if (type.is_array)
            return static_cast<ArrayType>(type).element_type;
        if (!type.is_aggregate) throw new TypeMismatchErr.NOT_AGGREGATE(
            @"Indexable type should be pointer or aggregate, but got $type"
        );
        var aty = static_cast<AggregateType>(type);
        if (aty.element_always_consist)
            return aty.get_elem(0);
        if (index == null) throw new RuntimeErr.NULL_PTR(
            @"$(Log.METHOD)::index cannot be null while type $type is not array-like"
        );
        if (index is IConstZero)
            return aty.get_elem(0);
        if (index is ConstInt)
            return aty.get_elem((size_t)static_cast<ConstInt>(index).u64_value);
        crash(@"$(Log.METHOD)::index should be compile-time constant while type $type is not array-like");
    }
}
