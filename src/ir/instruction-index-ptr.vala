public class Musys.IR.IndexPtrSSA: Instruction {
    private         Value       _source;
    private unowned Use         _usource;
    public  unowned PointerType source_ptr_type{get;}
    public PointerType target_type {
        get { return static_cast<PointerType>(_value_type); }
    }
    public Value source {
        get { return _source; }
        set { set_usee_type_match(_source_ptr_type, ref _source, value, _usource); }
    }

    public IndexUse[] indices{get;}
    private void _clean_indicies() {
        foreach (IndexUse i in indices)
            i.index = null;
        _indices = null;
    }

    public override void on_function_finalize() {
        value_fast_clean(ref _source, _usource);
        _clean_indicies();
        base._fast_clean();
    }
    public override void on_parent_finalize() {
        value_deep_clean(ref _source, _usource);
        _clean_indicies();
        base._deep_clean();
    }
    public override void accept(IValueVisitor visitor) {
        visitor.visit_inst_index_ptr(this);
    }

    public IndexPtrSSA.raw_move(PointerType source_type, PointerType type,
                                owned IndexUse[] indicies) {
        base.C1(INDEX_PTR_SSA, INDEX_PTR, type);
        this._usource = new SourceUse().attach_back(this);
        this._indices = (owned)indicies;
        foreach (IndexUse i in _indices)
            i.attach_back(this);
    }
    public IndexPtrSSA.from(PointerType src_ty, Value[] indicies) throws TypeMismatchErr
    {
        int len  = indicies.length;
        var uses = new IndexUse[len];
        Type curty = src_ty;
        try {
            for (int i = 0; i < len; i++) {
                var use = new IndexUse();
                curty = IRUtil.type_index(curty, indicies[i]);
                use._layer_type = curty;
                uses[i] = use;
            }
        } catch (RuntimeErr e) {
            crash(e.message);
        }
        this.raw_move(src_ty, IRUtil.get_ptr_type(curty), (owned)uses);
    }

    class construct { _istype[TID.INDEX_PTR_SSA] = true; }

    public class IndexUse: Use {
        private uint         _layer;
        private Value        _index;
        internal unowned Type _layer_type;
        public new IndexPtrSSA user {
            get { return static_cast<IndexPtrSSA>(_user); }
        }
        public Value index {
            get { return _index; }
            set {
                if (value == _index)
                    return;
                if (value != null && !value.value_type.is_int)
                    crash(@"Type mismatch: requires int in index[$_layer], but got $(value.value_type)");
                User.replace_use(_index, value, this);
                _index = value;
            }
        }
        public override Value? usee { get { return _index; } set { index = value; } }
    }
    public class SourceUse: Use {
        public new IndexPtrSSA user {
            get { return static_cast<IndexPtrSSA>(_user); }
        }
        public override Value? usee {
            get { return user._source; }
            set { user.source = value; }
        }
    }
}
