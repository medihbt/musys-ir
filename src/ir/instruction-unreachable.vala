namespace Musys.IR {
    public class UnreachableSSA: Instruction, IBasicBlockTerminator {
        public override void on_parent_finalize () {
            _nodeof_this = null;
        }
        public override void on_function_finalize () {
            _nodeof_this = null;
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

        public void forEachTarget(BasicBlock.ReadFunc fn) {}
        public void replaceTarget(BasicBlock.ReplaceFunc fn) {}
    }
}
