[CCode(gir_namespace="Musys", gir_version="0.0.1")]
namespace Musys.IRUtil.Value {
    public size_t replace_operand_with(IR.Value old, IR.Value novel)
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
    public size_t replace_operand_by(IR.Value old, IR.Use.ReplaceFunc replace)
    {
        var? uset = old.set_as_usee;
        if (uset == null || uset.is_empty)
            return 0;
        size_t usage = 0;
        foreach (var use in uset) {
            IR.Value? novel = replace(use);
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
