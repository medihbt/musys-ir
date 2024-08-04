namespace Musys.IRUtil {
    public Type type_index(Type type, IR.Value? index) throws TypeMismatchErr, RuntimeErr
    {
        if (type.is_pointer)
            return static_cast<PointerType>(type).target;
        if (type.is_array)
            return static_cast<ArrayType>(type).element_type;
        if (!type.is_aggregate) throw new TypeMismatchErr.MISMATCH(
            @"Indexable type should be pointer or aggregate, but got $type"
        );
        var aty = static_cast<AggregateType>(type);
        if (aty.always_has_same_type)
            return aty.get_element_type_at(0);
        if (index == null) throw new RuntimeErr.NULL_PTR(
            @"$(Log.METHOD)::index cannot be null while type $type is not array-like"
        );
        if (index.isvalue_by_id(ICONST_ZERO))
            return aty.get_element_type_at(0);
        if (index.isvalue_by_id(CONST_INT))
            return aty.get_element_type_at((size_t)static_cast<IR.ConstInt>(index).u64_value);
        crash(@"$(Log.METHOD)::index should be compile-time constant while type $type is not array-like");
    }

    public PointerType get_ptr_type(Type target) {
        return target.type_ctx.get_ptr_type(target);
    }
}
