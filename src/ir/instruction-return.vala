namespace Musys.IR {
    public class ReturnSSA: Instruction, IBasicBlockTerminator {
        private Value _retval;
        public  Value  retval {
            get { return _retval; }
            set {
                set_usee_type_match_self(ref _retval, value, operands.front());
            }
        }

        public void forEachTarget(BasicBlock.ReadFunc    fn) {}
        public void replaceTarget(BasicBlock.ReplaceFunc fn) {}

        public override void accept(IValueVisitor visitor) {
            visitor.visit_inst_return(this);
        }
        public override void on_parent_finalize()
        {
            if (_retval != null) {
                _retval.remove_use_as_usee(operands.front());
                _retval = null;
            }
            _nodeof_this = null;
            _parent      = null;
        }
        public override void on_function_finalize() {
            _retval      = null;
            _nodeof_this = null;
        }
        public ReturnSSA(Value retval) {
            base.C1(RET_SSA, RET, retval.value_type);
            new ReturnSSARetvalUse(this).attach_back(this);
        }
    }

    private sealed class ReturnSSARetvalUse: Use {
        public new ReturnSSA user {
            get { return static_cast<ReturnSSA>(_user); }
        }
        public override Value? usee {
            get { return  user.retval; }
            set { user.retval = value; }
        }
        public ReturnSSARetvalUse(ReturnSSA user) {
            base.C1(user);
        }
    }
}
