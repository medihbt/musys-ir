public class Musys.IR.UnreachableSSA: Instruction, IBasicBlockTerminator {
    public override void on_parent_finalize() {
        set_as_usee.clear();
        base._deep_clean();
    }
    public override void on_function_finalize() {
        set_as_usee.clear();
        base._fast_clean();
    }
    public override void accept (IValueVisitor visitor) {
        visitor.visit_inst_unreachable(this);
    }
    public UnreachableSSA(BasicBlock parent)
    {
        base.C1(UNREACHABLE_SSA, UNREACHABLE,
                parent.value_type.type_ctx.void_type);
    }
    class construct {
        _istype[TID.IBASIC_BLOCK_TERMINATOR] = true;
        _istype[TID.UNREACHABLE_SSA]         = true;
    }

    public bool foreach_target(BasicBlock.ReadFunc fn) { return false; }
    public bool replace_target(BasicBlock.ReplaceFunc fn) { return false; }
}
