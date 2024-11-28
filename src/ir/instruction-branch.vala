namespace Musys.IR {
    /**
     * === 分支跳转指令 ===
     *
     * 判断布尔条件 `condition` 是否为真. 若是, 则跳转到基本块 `if_true`;
     * 否则跳转到 `if_false`(也就是 `default_target`).
     *
     * Musys 显式区分有条件跳转和无条件跳转. 想要无条件跳转的话, 请使用
     * `JumpSSA` 类 (jump 指令).
     *
     * ==== 操作数表 ====
     *
     * - `[0] = condition` 跳转条件
     *
     * ==== 文本格式 ====
     *
     * {{{
     * br i1 <condition>, label <if true>, label <if false>
     * }}}
     *
     * @see Musys.IR.JumpSSA
     */
    public class BranchSSA: JumpBase {
        private Value        _condition;
        private unowned IntType _boolty;
        private unowned Use _ucondition;

        /** 决定分支向哪里的条件操作数. 必须是布尔类型的. */
        public Value condition {
            get { return _condition; }
            set {
                set_usee_type_match(_boolty, ref _condition, value, _ucondition);
            }
        }

        public unowned BasicBlock if_false {
            get { return default_target; } set { default_target = value; }
        }
        private unowned JumpTarget _if_true_target;
        public  unowned BasicBlock if_true{
            get { return _if_true_target.target; }
            set { _if_true_target.target = value; }
        }

        public override void on_parent_finalize ()
        {
            if_false = null; if_true = null;
            _nodeof_this = null;
            _parent      = null;
        }
        public override void accept(IValueVisitor visitor) {
            visitor.visit_inst_branch(this);
        }

        public BranchSSA.raw(VoidType voidty, IntType boolty) {
            base.C1(BR_SSA, BR, voidty);
            this._boolty = boolty;
            this._ucondition     = new BranchCondUse().attach_back(this);
            this._if_true_target = new JumpTarget(IF_TRUE).attach_back(this.jump_targets);
        }
        public BranchSSA.with(Value condition, BasicBlock if_false, BasicBlock if_true)
        {
            var boolty = value_bool_or_crash(
                condition, "at BranchSSA::with()::condition");
            var voidty = boolty.type_ctx.void_type;
            this.raw(voidty, boolty);
            this.condition = condition;
            this.if_true   = if_true;
            this.if_false  = if_false;
        }
        class construct { _istype[TID.BR_SSA] = true; }
    }

    private sealed class BranchCondUse: Use {
        public new BranchSSA user {
            get { return static_cast<BranchSSA>(_user); }
        }
        public override Value? usee {
            get { return user.condition;  }
            set { user.condition = value; }
        }
    }
}
