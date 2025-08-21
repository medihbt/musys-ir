namespace MusysIR.ValueUtil {
    public size_t replace_operand_with(Value old, Value novel)
    {
        if (old == novel)
            return 0;
        var? uset = old.set_as_usee;
        if (uset == null || uset.is_empty)
            return 0;
        size_t usage = 0;
        foreach (var use in uset) {
            usage++;
            use.usee = novel;
        }
        return usage;
    }
    public size_t replace_operand_by(Value old, Use.ReplaceFunc replace)
    {
        var? uset = old.set_as_usee;
        if (uset == null || uset.is_empty)
            return 0;
        size_t usage = 0;
        foreach (var use in uset) {
            Value? novel = replace(use);
            if (novel == null)
                return usage;
            if (novel == old)
                continue;
            use.usee = novel;
            usage++;
        }
        return usage;
    }
} // namespace Musys.IRUtil.Value
