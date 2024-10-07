namespace Musys.IR {
    /**
     * === 跳转类指令 ===
     *
     * 位于基本块结尾，负责决定执行流的下一个基本块在哪里的指令.
     * 由于跳转类指令的跳转目标集合不会随着数据流改变，也不会混入数据流里作为操作数,
     * 因此 JumpBase 里所有的静态跳转目标都不是操作数, 不需要分配 Use 子类.
     */
    public abstract class JumpBase: Instruction, IBasicBlockTerminator {
        protected unowned BasicBlock _default_target;
        public override unowned BasicBlock? default_target {
            get { return _default_target;  }
            set { _default_target = value; }
        }
    
        protected abstract void foreach_target(BasicBlock.ReadFunc    fn);
        protected abstract void replace_target(BasicBlock.ReplaceFunc fn);
        protected abstract int64 do_get_n_targets();

        public void forEachTarget(BasicBlock.ReadFunc    fn) { foreach_target(fn); }
        public void replaceTarget(BasicBlock.ReplaceFunc fn) { replace_target(fn); }
        
        /**
         * {@inheritDoc}
         */
        public int64 ntargets { get { return do_get_n_targets(); } }

        protected JumpBase.C1(Value.TID tid, OpCode opcode, VoidType voidty) {
            base.C1(tid, opcode, voidty);
        }
        class construct {
            _istype[TID.JUMP_BASE]               = true;
            _istype[TID.IBASIC_BLOCK_TERMINATOR] = true;
        }
    } // abstract class JumpBase
}
