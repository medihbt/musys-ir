public class Musys.IR.ReturnSSA: Instruction, IBasicBlockTerminator {
    private Value _retval;
    public  Value  retval {
        get { return _retval; }
        set {
            set_usee_type_match_self(ref _retval, value, operands.front());
        }
    }
    private JumpTargetList? _jump_targets = null;
    protected unowned JumpTargetList get_jump_target_impl() {
        if (_jump_targets == null)
            _jump_targets = new JumpTargetList(this);
        return _jump_targets;
    }
    public bool has_jump_target() { return false; }

    public override void accept(IValueVisitor visitor) {
        visitor.visit_inst_return(this);
    }
    public override void on_parent_finalize() {
        value_deep_clean(ref _retval, operands.front());
        base._deep_clean();
    }
    public override void on_function_finalize() {
        value_fast_clean(ref _retval, operands.front());
        base._fast_clean();
    }
    public ReturnSSA.raw(Type return_type) {
        base.C1(RET_SSA, RET, return_type);
        new RetvalUse(this).attach_back(this);
    }
    public ReturnSSA(Value retval) {
        base.C1(RET_SSA, RET, retval.value_type);
        new RetvalUse(this).attach_back(this);
        this.retval = retval;
    }
    class construct {
        _istype[TID.RET_SSA]                 = true;
        _istype[TID.IBASIC_BLOCK_TERMINATOR] = true;
    }

    private sealed class RetvalUse: Use {
        public new ReturnSSA user {
            get { return static_cast<ReturnSSA>(_user); }
        }
        public override Value? usee {
            get { return  user.retval; }
            set { user.retval = value; }
        }
        public RetvalUse(ReturnSSA user) {
            base.C1(user);
        }
    }
}
