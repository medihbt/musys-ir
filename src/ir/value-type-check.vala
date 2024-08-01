namespace Musys.IR {
    public IntType?   value_int_or_crash(Value? value, string msg = "")
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
    public unowned IntType value_bool_or_crash(Value value, string msg = "")
    {
        unowned Type t = value.value_type;
        if (t.is_int && static_cast<IntType>(t).binary_bits == 1)
            return static_cast<IntType>(t);
        crash(@"Value type mismatch: requires bool, but got $(t)\nadditional: $(msg)",
              true, {Log.FILE, Log.METHOD, Log.LINE});
    }
    public FloatType? value_float_or_crash(Value? value, string msg = "")
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
    public PointerType? value_ptr_or_crash(Value? value, string msg = "")
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
}
