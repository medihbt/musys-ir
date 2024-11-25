namespace Musys.IR {
    public Type? check_value_istype_throw(Value? value, Type.TID tid, string? fmt, va_list ap)
                throws TypeMismatchErr {
        if (value == null)
            return null;
        Type valuety = value.value_type;
        if (valuety.istype_by_id(tid))
            return valuety;
        throw error_type_mismatch_by_id(tid,
            @"Requires $(tid.nickname()), but got $valuety; additional ",
            fmt, ap);
    }

    [Diagnostics, PrintfFormat]
    public PrimitiveType? value_primitive_or_crash(Value? value, string fmt = "", ...)
    {
        try {
            return (PrimitiveType?)
                check_value_istype_throw(value, PRIMITIVE_TYPE, fmt, va_list());
        } catch (Error e) { crash_err(e); }
    }

    [Diagnostics, PrintfFormat]
    public IntType? value_int_or_throw(Value? value, string fmt = "", ...)
                throws TypeMismatchErr {
        return static_cast<IntType?>(
            check_value_istype_throw(value, INT_TYPE, fmt, va_list()));
    }
    [Diagnostics, PrintfFormat]
    public IntType? value_int_or_crash(Value? value, string fmt = "", ...)
    {
        try {
            return static_cast<IntType?>(
                check_value_istype_throw(value, INT_TYPE, fmt, va_list()));
        } catch (Error e) { crash_err(e); }
    }

    [Diagnostics, PrintfFormat]
    public unowned IntType? value_bool_or_crash(Value? value, string fmt = "", ...)
    {
        if (value == null)
            return null;
        unowned Type t = value.value_type;
        if (t.is_int && static_cast<IntType>(t).binary_bits == 1)
            return static_cast<IntType>(t);
        crash(@"Requires boolean value but got $t; additional $(fmt.vprintf(va_list()))");
    }
    [Diagnostics, PrintfFormat]
    public unowned IntType? value_bool_or_throw(Value? value, string fmt = "", ...)
                throws TypeMismatchErr {
        if (value == null)
            return null;
        unowned Type t = value.value_type;
        if (t.is_int && static_cast<IntType>(t).binary_bits == 1)
            return static_cast<IntType>(t);
        throw new TypeMismatchErr.NOT_BOOLEAN(
            "Requires boolean value but got %s; additional %s",
            t.to_string(), fmt.vprintf(va_list()));
    }

    [Diagnostics, PrintfFormat]
    public unowned FloatType? value_float_or_throw(Value? value, string fmt = "", ...)
                throws TypeMismatchErr {
        return static_cast<FloatType?>(
            check_value_istype_throw(value, FLOAT_TYPE, fmt, va_list()));
    }
    [Diagnostics, PrintfFormat]
    public unowned FloatType? value_float_or_crash(Value? value, string fmt = "", ...)
    {
        try {
            return static_cast<FloatType?>(
                check_value_istype_throw(value, FLOAT_TYPE, fmt, va_list()));
        } catch (Error e) { crash_err(e); }
    }

    [Diagnostics, PrintfFormat]
    public unowned AggregateType value_aggr_or_throw(Value? value, string fmt = "", ...)
                throws TypeMismatchErr {
        return static_cast<AggregateType>(
            check_value_istype_throw(value, AGGR_TYPE, fmt, va_list()));
    }

    [Diagnostics, PrintfFormat]
    public unowned PointerType? value_ptr_or_throw(Value? value, string fmt = "", ...)
                throws TypeMismatchErr {
        return static_cast<PointerType?>(
            check_value_istype_throw(value, OPAQUE_PTR_TYPE, fmt, va_list()));
    }
    [Diagnostics, PrintfFormat]
    public unowned PointerType? value_ptr_or_crash(Value? value, string fmt = "", ...)
    {
        try {
            return static_cast<PointerType?>(
                check_value_istype_throw(value, OPAQUE_PTR_TYPE, fmt, va_list()));
        } catch (Error e) { crash_err(e); }
    }

    [Diagnostics, PrintfFormat]
    public void type_match_or_crash(Type required, Type value, string fmt = "", ...)
    {
        if (required.equals(value))
            return;
        crash(@"Type mismatch: requires $required, but got $value; additional: $(fmt.vprintf(va_list()))");
    }
    [Diagnostics, PrintfFormat]
    public void type_match_or_throw(Type required, Type value, string fmt = "", ...)
                throws TypeMismatchErr {
        if (required.equals(value))
            return;
        throw new TypeMismatchErr.MISMATCH(
            @"Type mismatch: requires $required, but got $value; additional: $(fmt.vprintf(va_list()))");
    }
    public unowned Type type_match_istid_v(Type lty, Type rty, Type.TID tid, string msgfmt, va_list ap)
            throws TypeMismatchErr {
        if (!lty.equals(rty))
            throw new TypeMismatchErr.MISMATCH(@"Type $lty and $rty unmatch");
        if (lty.istype_by_id(tid))
            return lty;
        throw error_type_mismatch_by_id(tid,
            @"Requires $(tid.nickname()), but got $lty; additional ",
            msgfmt, ap);
    }
    [Diagnostics, PrintfFormat]
    public unowned Type type_match_istid(Type lty, Type rty, Type.TID tid, string msgfmt = "", ...)
            throws TypeMismatchErr {
        return type_match_istid_v(lty, rty, tid, msgfmt, va_list());
    }

    public void type_bit_same_or_throw(Type l, Type r)
                throws TypeMismatchErr {
        if (l == r)
            return;
        size_t lbit = 0, rbit = 0;
        if (l.is_valuetype && r.is_valuetype) {
            lbit = static_cast<PrimitiveType>(l).binary_bits;
            rbit = static_cast<PrimitiveType>(r).binary_bits;
        } else {
            lbit = l.instance_size * 8;
            rbit = r.instance_size * 8;
        }
        if (lbit != rbit) {
            throw new TypeMismatchErr.BITS_NOT_SAME(
                @"type L($l, $lbit bits) and R($r, $rbit bits) should have same size");
        }
    }

    public unowned IntType get_bool_type(Type type)
    {
        if (type.is_int && static_cast<IntType>(type).binary_bits == 1)
            return static_cast<IntType>(type);
        return type.type_ctx.bool_type;
    }
    public unowned PointerType get_ptr_type(Type type) {
        if (type.is_pointer)
            return (PointerType)type;
        return type.type_ctx.opaque_ptr;
    }

    /**
     * ''迭代函数'': 检查传入的 `index` 是否匹配解包前的类型 `before_extracted`
     *
     * 因为这是个迭代函数, 所以返回值 `true` 表示终止迭代, `false` 表示继续迭代.
     *
     * 注意, 因为 IndexPtrSSA 有对 0 长度数组做解包的情况, 所以 IR 内不要对数组
     * 是否越界做任何检查.
     *
     * @return 迭代函数返回值, `true` 表示终止迭代, `false` 表示继续迭代.
     */
    public bool check_type_index_step(Value? index, uint layer,
                                      Type before_extract,
                                      out Type after_extract)
                throws TypeMismatchErr, IndexPtrErr
    {
        if (!before_extract.is_aggregate) {
            throw new TypeMismatchErr.NOT_AGGREGATE(
                "IndexPtrSSA layer %u (type %s) requires aggregate type to extract",
                layer, before_extract.to_string()
            );
        }
        var aggr_bex = static_cast<AggregateType>(before_extract);

        /* 对于数组、向量这种元素统一的类型, 直接返回即可. 结构体才要做 extract.
         * 注意, 因为 IndexPtrSSA 有对 0 长度数组做解包的情况, 所以 IR 内不要对数组
         * 是否越界做任何检查. */
        if (aggr_bex.element_always_consist) {
            after_extract = aggr_bex.get_elem(0);
            return false;
        }

        /* 不透明结构体不可索引. */
        if (aggr_bex.is_struct && static_cast<StructType>(aggr_bex).is_opaque) {
            throw new TypeMismatchErr.STRUCT_OPAQUE(
                "IndexPtrSSA layer %u (type %s) is opqaue structure, which means it cannot be extracted",
                layer, before_extract.to_string()
            );
        }

        /* 结构体的索引必须是常量 */
        if (unlikely(index == null || !index.isvalue_by_id(CONST_INT))) {
            throw new IndexPtrErr.INDEX_NOT_CONSTANT(
                "IndexPtrSSA layer %u (type %s) is not array or vector, "+
                "while it received an unexpected non-constant index %s",
                layer, before_extract.to_string(),
                index == null? "(null)": index.get_type().name()
            );
        }
        /* 结构体索引不能超限 */
        var iconst_index = static_cast<ConstInt>(index);
        after_extract = aggr_bex.get_elem((size_t)iconst_index.i64_value);
        if (unlikely(after_extract.is_void)) {
            throw new IndexPtrErr.INDEX_OVERFLOW(
                "IndexPtrSSA layer %u (type {%s}) index[%l] overflow",
                layer, before_extract.to_string(),
                iconst_index.i64_value
            );
        }
        return false;
    }
}
