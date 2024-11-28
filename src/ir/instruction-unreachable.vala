public class Musys.IR.UnreachableSSA: Instruction, IBasicBlockTerminator {
    public override void on_parent_finalize() {
        set_as_usee.clear();
        base._deep_clean();
    }
    public override void on_function_finalize() {
        set_as_usee.clear();
        base._fast_clean();
    }
    public override void accept(IValueVisitor visitor) {
        visitor.visit_inst_unreachable(this);
    }

    private JumpTargetList? _jump_targets = null;
    protected unowned JumpTargetList get_jump_target_impl() {
        if (_jump_targets == null)
            _jump_targets = new JumpTargetList(this);
        return _jump_targets;
    }

    public UnreachableSSA(BasicBlock parent)
    {
        base.C1(UNREACHABLE_SSA, UNREACHABLE,
                parent.value_type.type_ctx.void_type);
    }
    public UnreachableSSA.@void(VoidType voidty) {
        base.C1(UNREACHABLE_SSA, UNREACHABLE, voidty);
    }
    class construct {
        _istype[TID.IBASIC_BLOCK_TERMINATOR] = true;
        _istype[TID.UNREACHABLE_SSA]         = true;
    }
}
