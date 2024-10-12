public abstract class Musys.IR.IndexSSABase: Instruction {
    protected       Value _aggregate;
    protected       Value _index;
    protected unowned Use _usrc;
    protected unowned Use _uindex;
    internal unowned AggregateType _aggregate_type;
    public   unowned AggregateType  aggregate_type
    {
        get { return _aggregate_type; }
        internal set {
            if (!(value.element_consist)) {
                crash_fmt(
                    "IndexSSABase::aggregate_type requires consistant aggregate " +
                    "type, but got %s",
                    value.to_string()
                );
            }
            _aggregate_type = value;
        }
    }
    public Type element_type{
        owned get { return aggregate_type.get_element_type_at(0); }
    }

    public Value aggregate {
        get { return _aggregate; }
        set { set_usee_type_match(aggregate_type, ref _aggregate, value, _usrc); }
    }
    public Value index {
        get { return _index; }
        set {
            if (value == _index)
                return;
            value_int_or_crash(value, "at IndexBaseSSA.index::set");
            replace_use(_index, value, _uindex);
            _index = value;
        }
    }

    public override void on_function_finalize() { _fast_clean(); }
    public override void on_parent_finalize()   { _deep_clean(); }
    protected new void _deep_clean()
    {
        this.index = null;
        this.aggregate = null;
        base._deep_clean();
    }
    protected new void _fast_clean() {
        this._index = null;
        this._aggregate = null;
        base._fast_clean();
    }
    protected IndexSSABase.C1(Value.TID tid, OpCode opcode,
                              AggregateType aggregate_type,
                              Type type)
    {
        base.C1(tid, opcode, type);
        this.aggregate_type = aggregate_type;
        this._usrc   = new ArrayUse().attach_back(this);
        this._uindex = new IndexUse().attach_back(this);
    }
    class construct { _istype[TID.INDEX_SSA_BASE] = true; }

    private sealed class ArrayUse: Use {
        public new IndexSSABase user {
            get { return static_cast<IndexSSABase>(_user); }
        }
        public override Value? usee {
            get { return user.aggregate; } set { user.aggregate = value; }
        }
    }
    private sealed class IndexUse: Use {
        public new IndexSSABase user {
            get { return static_cast<IndexSSABase>(_user); }
        }
        public override Value? usee {
            get { return user.index; } set { user.index = value; }
        }
    }
}
