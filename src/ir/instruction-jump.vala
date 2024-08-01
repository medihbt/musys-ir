namespace Musys.IR {
    public class JumpSSA: JumpBase {
        public unowned BasicBlock target {
            get { return _default_target;  }
            set { _default_target = value; }
        }
        protected override void foreach_target(BasicBlock.ReadFunc fn) {
            fn(default_target);
        }
        protected override void replace_target(BasicBlock.ReplaceFunc fn)
        {
            var target = fn(default_target);
            if (target == null || target == _default_target)
                return;
            default_target = target;
        }
        public override void on_parent_finalize() {
            _default_target = null;
            _nodeof_this    = null;
        }
        public override void accept (IValueVisitor visitor) {
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
}
