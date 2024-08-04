public abstract class Musys.IR.IndexSSABase: Instruction {
    protected         Value    _array;
    protected         Value    _index;
    protected unowned Use      _usrc;
    protected unowned Use      _uindex;
    public    unowned ArrayType array_type{get; protected set;}
    public    unowned Type    element_type{
        get { return array_type.element_type; }
    }

    public Value array {
        get { return _array; }
        set { set_usee_type_match(array_type, ref _array, value, _usrc); }
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
        this.array = null;
        base._deep_clean();
    }
    protected new void _fast_clean() {
        this._index = null;
        this._array = null;
        base._fast_clean();
    }
    protected IndexSSABase.C1(Value.TID tid,    OpCode opcode,
                              ArrayType array_type, Type type)
    {
        base.C1(tid, opcode, type);
        this._array_type = array_type;
        this._usrc   = new ArrayUse().attach_back(this);
        this._uindex = new IndexUse().attach_back(this);
    }
    class construct { _istype[TID.INDEX_SSA_BASE] = true; }

    private sealed class ArrayUse: Use {
        public new IndexSSABase user {
            get { return static_cast<IndexSSABase>(_user); }
        }
        public override Value? usee {
            get { return user.array; } set { user.array = value; }
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
