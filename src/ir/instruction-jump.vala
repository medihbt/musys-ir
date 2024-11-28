public class Musys.IR.JumpSSA: JumpBase {
    public override void on_parent_finalize() {
        _default_target = null; base._deep_clean();
    }
    public override void on_function_finalize() {
        _default_target = null;
        base._fast_clean();
    }
    public override void accept(IValueVisitor visitor) {
        visitor.visit_inst_jump(this);
    }
    public BasicBlock target {
        get { return default_target; } set { default_target = value; }
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
