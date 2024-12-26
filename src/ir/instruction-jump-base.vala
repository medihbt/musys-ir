namespace Musys.IR {
    /**
     * === 跳转类指令 ===
     *
     * 位于基本块结尾，负责决定执行流的下一个基本块在哪里的指令.
     * 由于跳转类指令的跳转目标集合不会随着数据流改变，也不会混入数据流里作为操作数,
     * 因此 JumpBase 里所有的静态跳转目标都不是操作数, 不需要分配 Use 子类.
     */
    public abstract class JumpBase: Instruction, IBasicBlockTerminator {
        protected unowned JumpTargetList get_jump_target_impl() {
            return this._jump_targets;
        }
        public JumpTargetList jump_targets { get; internal set; }

        protected unowned JumpTarget _default_target;
        public BasicBlock default_target {
            get { return _default_target.target; } set { _default_target.target = value; }
        }
        /**
         * {@link Musys.IR.IBasicBlockTerminator.ntargets}
         */
        public int64 ntargets { get { return jump_targets.length; } }

        public bool has_jump_target() { return true; }

        public override bool terminates_function() {
            return false;
        }

        protected JumpBase.C1(Value.TID tid, OpCode opcode, VoidType voidty) {
            base.C1(tid, opcode, voidty);
            this.jump_targets    = new JumpTargetList(this);
            this._default_target = new JumpTarget(DEFAULT).attach_back(jump_targets);
        }
        class construct {
            _istype[TID.JUMP_BASE]               = true;
            _istype[TID.IBASIC_BLOCK_TERMINATOR] = true;
        }
    } // abstract class JumpBase
}
