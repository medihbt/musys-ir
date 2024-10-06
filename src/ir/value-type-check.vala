namespace Musys.IR {
    public IntType? value_int_or_crash(Value? value, string msg = "")
    {
        if (value == null)
            return null;
        unowned Value v = value;
        unowned Type  t = v.value_type;
        if (t.is_int)
            return static_cast<IntType>(t);
        crash(@"Value type mismatch: requires int, but got $(t)\nadditional: $(msg)",
              true, {Log.FILE, Log.METHOD, Log.LINE});
    }
    [PrintfFormat]
    public IntType? value_int_or_crash_fmt(Value? value, string fmt, ...)
    {
        if (value == null)
            return null;
        unowned Value v = value;
        unowned Type  t = v.value_type;
        if (t.is_int)
            return static_cast<IntType>(t);
        critical("Value type mismatch: requires int, but got %s.", t.to_string());
        crash_vfmt(Musys.SourceLocation.current(), fmt, va_list());
    }
    public unowned IntType value_bool_or_crash(Value value, string msg = "")
    {
        unowned Type t = value.value_type;
        if (t.is_int && static_cast<IntType>(t).binary_bits == 1)
            return static_cast<IntType>(t);
        crash(@"Value type mismatch: requires bool, but got $(t)\nadditional: $(msg)",
              true, {Log.FILE, Log.METHOD, Log.LINE});
    }
    public unowned FloatType? value_float_or_crash(Value? value, string msg = "")
    {
        if (value == null)
            return null;
        unowned Value v = value;
        unowned Type  t = v.value_type;
        if (t.is_float)
            return static_cast<FloatType>(t);
        crash(@"Value type mismatch: requires float, but got $(t)\nadditional: $(msg)",
              true, {Log.FILE, Log.METHOD, Log.LINE});
    }
    public unowned PointerType? value_ptr_or_crash(Value? value, string msg = "")
    {
        if (value == null)
            return null;
        unowned Value v = value;
        unowned Type  t = v.value_type;
        if (t.is_pointer)
            return static_cast<PointerType>(t);
        crash(@"Value type mismatch: requires pointer, but got $(t)\nadditional: $(msg)",
            true, {Log.FILE, Log.METHOD, Log.LINE});
    }

    public unowned IntType   type_int_or_crash(Type type)
    {
        if (type.is_int)
            return static_cast<IntType>(type);
        crash(@"Type mismatch: requires int, but got $type",
              true, {Log.FILE, Log.METHOD, Log.LINE});
    }
    public unowned FloatType type_float_or_crash(Type type)
    {
        if (type.is_float)
            return static_cast<FloatType>(type);
        crash(@"Type mismatch: requires float, but got $type",
              true, {Log.FILE, Log.METHOD, Log.LINE});
    }
    public unowned PointerType type_ptr_or_crash(Type type)
    {
        if (type.is_pointer)
            return static_cast<PointerType>(type);
        crash(@"Type mismatch: requires pointer type, but got $type",
              true, {Log.FILE, Log.METHOD, Log.LINE});
    }

    public void type_match_or_crash(Type required, Type value,
                                    SourceLocation current = SourceLocation.current())
    {
        if (required.equals(value))
            return;
        crash(@"Type mismatch: requires $(required), but got $(value)",
              true, current);
    }
    public unowned IntType int_value_match_or_crash(Value lhs, Value rhs)
    {
        unowned var lty = lhs.value_type;
        unowned var rty = rhs.value_type;
        if (!lty.is_int || !rty.is_int) {
            crash(@"instruction requires int type, but:\nlhs is $(lty)\nrhs is $(rty)"
                  , true, {Log.FILE, Log.METHOD, Log.LINE});
        }
        if (!lty.equals(rty)) {
            crash(@"instruction requires LHS and RHS type be the same, but:\nlhs is $(lty)\nrhs is $(rty)"
                  , true, {Log.FILE, Log.METHOD, Log.LINE});
        }
        return static_cast<IntType>(lty);
    }

    public bool type_bit_same(Type l, Type r) {
        if (l.equals(r))
            return true;
        size_t lbit = 0, rbit = 0;
        if (l.is_valuetype && r.is_valuetype) {
            lbit = static_cast<PrimitiveType>(l).binary_bits;
            rbit = static_cast<PrimitiveType>(r).binary_bits;
            if (lbit == rbit)
                return true;
        } else {
            lbit = l.instance_size;
            rbit = r.instance_size;
            if (lbit == rbit)
                return true;
            lbit *= 8; rbit *= 8;
        }
        return false;
    }
    public void type_bit_same_or_crash(Type l, Type r)
    {
        if (l.equals(r))
            return;
        size_t lbit = 0, rbit = 0;
        if (l.is_valuetype && r.is_valuetype) {
            lbit = static_cast<PrimitiveType>(l).binary_bits;
            rbit = static_cast<PrimitiveType>(r).binary_bits;
            if (lbit == rbit)
                return;
        } else {
            lbit = l.instance_size;
            rbit = r.instance_size;
            if (lbit == rbit)
                return;
            lbit *= 8; rbit *= 8;
        }
        crash(@"type L($l, $lbit bits) and R($r, $rbit bits) should have same size",
              true, {Log.FILE, Log.METHOD, Log.LINE});
    }

    public IntType get_bool_type(Type type)
    {
        if (type.is_int && static_cast<IntType>(type).binary_bits == 1)
            return static_cast<IntType>(type);
        return type.type_ctx.bool_type;
    }

    /**
     * ''迭代函数'': 检查传入的 `index` 是否匹配解包前的类型 `before_extracted`
     *
     * 因为这是个迭代函数, 所以返回值 `true` 表示终止迭代, `false` 表示继续迭代.
     *
     * @return 迭代函数返回值, `true` 表示终止迭代, `false` 表示继续迭代.
     */
    public bool check_type_index_step(Value index, uint layer,
                    Type before_extracted, out Type after_extracted)
                throws TypeMismatchErr, IndexPtrErr
    {
        if (!before_extracted.is_aggregate) {
            throw new TypeMismatchErr.NOT_AGGREGATE(
                "IndexPtrSSA layer %u (type %s) requires aggregate type to extract",
                layer, before_extracted.to_string()
            );
        }
        var aggr_bex = static_cast<AggregateType>(before_extracted);

        /* 对于数组、向量这种元素统一的类型, 直接返回即可. 结构体才要做 extract. */
        if (aggr_bex.element_always_consist) {
            after_extracted = aggr_bex.get_element_type_at(0);
            return false;
        }

        /* 不透明结构体不可索引. */
        if (aggr_bex.is_struct && static_cast<StructType>(aggr_bex).is_opaque) {
            throw new TypeMismatchErr.STRUCT_OPAQUE(
                "IndexPtrSSA layer %u (type %s) is opqaue structure, which means it cannot be extracted",
                layer, before_extracted.to_string()
            );
        }

        /* 结构体的索引必须是常量 */
        if (unlikely(index == null || !index.isvalue_by_id(CONST_INT))) {
            throw new IndexPtrErr.INDEX_NOT_CONSTANT(
                "IndexPtrSSA layer %u (type %s) is not array or vector, "+
                "while it received an unexpected non-constant index %s",
                layer, before_extracted.to_string(),
                index == null? "(null)": index.get_type().name()
            );
        }
        /* 结构体索引不能超限 */
        var iconst_index = static_cast<ConstInt>(index);
        after_extracted = aggr_bex.get_element_type_at((size_t)iconst_index.i64_value);
        if (unlikely(after_extracted.is_void)) {
            throw new IndexPtrErr.INDEX_OVERFLOW(
                "IndexPtrSSA layer %u (type {%s}) index[%l] overflow",
                layer, before_extracted.to_string(),
                iconst_index.i64_value
            );
        }
        return false;
    }
}
