public class Musys.IR.JumpSSA: JumpBase {
    public unowned BasicBlock target {
        get { return _default_target;  }
        set { _default_target = value; }
    }
    protected override ForeachResult foreach_jump_target(BasicBlock.ReadFunc fn) {
        return ForeachResult.FromMusys(fn(default_target));
    }
    protected override ForeachResult replace_jump_target(BasicBlock.ReplaceFunc fn)
    {
        var target = fn(default_target);
        if (target == null || target == _default_target)
            return ForeachResult.FromMusys(target != null);
        default_target = target;
        return ForeachResult.CONTINUE;
    }
    protected override int64 n_jump_targets() { return 1; }
    public override void on_parent_finalize() {
        _default_target = null;
        base._deep_clean();
    }
    public override void on_function_finalize() {
        _default_target = null;
        base._fast_clean();
    }
    public override void accept(IValueVisitor visitor) {
        visitor.visit_inst_jump(this);
    }

    public JumpSSA.raw(VoidType voidty) {
        base.C1(JUMP_SSA, JMP, voidty);
    }
    public JumpSSA(BasicBlock target) {
        this.raw(target.value_type.type_ctx.void_type);
        this.default_target = target;
    }
    class construct { _istype[TID.JUMP_SSA] = true; }
}
