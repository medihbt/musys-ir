/**
 * === 数据二选一指令 ===
 *
 * 根据布尔条件 ``condition`` 的值, 在 ``if_true`` 和 ``if_false`` 中选一个作为
 * 该指令的返回值.
 *
 * ==== 操作数表 ====
 *
 * * ``[0] = condition``: 布尔条件
 *
 * * ``[1] = if_true``:  条件成立时选择这个值
 *
 * * ``[2] = if_false``: 条件不成立时选择这个值
 *
 * ==== 文本格式 ====
 *
 * `%<id> = select i1 <condition>, <type> <if_true>, <if_false>`
 */
public class Musys.IR.BinarySelectSSA: Instruction {
    private Value _condition;
    private Value _if_true;
    private Value _if_false;
    private unowned IR.Use _ucondition;
    private unowned IR.Use _uif_true;
    private unowned IR.Use _uif_false;

    public Value condition {
        get { return _condition; }
        set {
            value_bool_or_crash(value, "BinarySelectSSA.condition");
            User.set_usee_always(ref _condition, value, _ucondition);
        }
    }
    public Value if_true {
        get { return _if_true; }
        set { set_usee_type_match_self(ref _if_true, value, _uif_true); }
    }
    public Value if_false {
        get { return _if_false; }
        set { set_usee_type_match_self(ref _if_false, value, _uif_false); }
    }

    public override void accept(IValueVisitor visitor) {
        visitor.visit_inst_select(this);
    }
    public override void on_parent_finalize()   { _deep_clean(); }
    public override void on_function_finalize() { _deep_clean(); }
    protected new void _deep_clean() {
        this.condition = null;
        this.if_true   = null;
        this.if_false  = null;
    }

    public BinarySelectSSA.raw(Type value_type) {
        base.C1(SELECT_SSA, SELECT, value_type);
        this._ucondition = new Use(CONDITION).attach_back(this);
        this._uif_true   = new Use(IF_TRUE).attach_back(this);
        this._uif_false  = new Use(IF_FALSE).attach_back(this);
    }
    public BinarySelectSSA.from(Value condition, Value if_true, Value if_false) {
        this.raw(if_true.value_type);
        this.condition = condition;
        this.if_true   = if_true;
        this.if_false  = if_false;
    }

    private sealed class Use: IR.Use {
        public OperandOrder order;
        public new BinarySelectSSA user {
            get { return (BinarySelectSSA)_user; }
            set { _user = value; }
        }
        public override Value? usee {
            get {
                switch (order) {
                case OperandOrder.CONDITION: return user.condition;
                case OperandOrder.IF_TRUE:   return user.if_true;
                case OperandOrder.IF_FALSE:  return user.if_false;
                default: crash_fmt("Unreachable: unrecognized `Use` index %d", order);
                }
            }
            set {
                switch (order) {
                case OperandOrder.CONDITION: user.condition = value; break;
                case OperandOrder.IF_TRUE:   user.if_true   = value; break;
                case OperandOrder.IF_FALSE:  user.if_false  = value; break;
                default: crash_fmt("Unreachable: unrecognized `Use` index %d", order);
                }
            }
        }
        internal Use(OperandOrder index) {
            this.order = index;
        }
    }

    public enum OperandOrder {
        CONDITION, IF_TRUE, IF_FALSE;
    }
}
