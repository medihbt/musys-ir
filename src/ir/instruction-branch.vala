namespace Musys.IR {
    public class BranchSSA: JumpBase {
        private Value        _condition;
        private unowned IntType _boolty;
        private unowned Use _ucondition;
        public Value condition {
            get { return _condition; }
            set {
                set_usee_type_match(_boolty, ref _condition, value, _ucondition);
            }
        }

        public unowned BasicBlock if_false {
            get { return _default_target;  }
            set { _default_target = value; }
        }
        public unowned BasicBlock if_true{get;set;}

        protected override void foreach_target(BasicBlock.ReadFunc fn) {
            if (fn(if_false)) 
                return;
            fn(if_true);
        }
        protected override void replace_target(BasicBlock.ReplaceFunc fn)
        {
            BasicBlock? replaced = null;
            BasicBlock  if_false = this.if_false;
            BasicBlock  if_true  = this.if_true;

            replaced = fn(if_false);
            if (replaced == null)     return;
            if (replaced != if_false) this.if_false = replaced;

            replaced = fn(if_true);
            if (replaced == null)     return;
            if (replaced != if_true)  this.if_true  = replaced;
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
            this._ucondition = new BranchCondUse().attach_back(this);
        }
        public BranchSSA.with(Value condition, BasicBlock if_false, BasicBlock if_true)
        {
            var boolty = value_bool_or_crash(
                condition, "at BranchSSA::with()::condition");
            var voidty = boolty.type_ctx.void_type;
            this.raw(voidty, boolty);
            this.condition = condition;
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
