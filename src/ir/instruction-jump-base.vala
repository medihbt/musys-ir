namespace Musys.IR {
    public abstract class JumpBase: Instruction, IBasicBlockTerminator {
        protected unowned BasicBlock _default_target;
        public override unowned BasicBlock? default_target {
            get { return _default_target;  }
            set { _default_target = value; }
        }
    
        protected abstract void foreach_target(BasicBlock.ReadFunc    fn);
        protected abstract void replace_target(BasicBlock.ReplaceFunc fn);

        public void forEachTarget(BasicBlock.ReadFunc    fn) { foreach_target(fn); }
        public void replaceTarget(BasicBlock.ReplaceFunc fn) { replace_target(fn); }

        protected JumpBase.C1(Value.TID tid, OpCode opcode, VoidType voidty) {
            base.C1(tid, opcode, voidty);
        }
        class construct {
            _istype[TID.JUMP_BASE]               = true;
            _istype[TID.IBASIC_BLOCK_TERMINATOR] = true;
        }
    }

#if BASICBLOCK_AS_VALUE
    private sealed class JumpDefaultTargetUse: Use {
        public new JumpBase user {
            get { return static_cast<JumpBase>(_user); }
        }
        public override Value? usee {
            get { return user.default_target; }
            set {
                if (value == null)
                    user.default_target = null;
                var bvalue = value as BasicBlock;
                if (bvalue == null)
                    crash(@"JumpBase.default_target requires `BasicBlock`, but got `$(value.get_class().get_name())`");
                user.default_target = bvalue;
            }
        }
    }
#endif
}
