public class Musys.IR.IndexInsertSSA: IndexSSABase {
    private         Value _element;
    private unowned Use  _uelement;
    public Value element {
        get { return _element; }
        set { set_usee_type_match(element_type, ref _element, value, _uelement); }
    }

    public override void on_parent_finalize() {
        value_deep_clean(ref _element, _uelement);
        base._deep_clean();
    }
    public override void on_function_finalize() {
        value_fast_clean(ref _element, _uelement);
        base._fast_clean();
    }
    public override void accept(IValueVisitor visitor) {
        visitor.visit_inst_index_insert(this);
    }
    public IndexInsertSSA.raw(ArrayType array_type) {
        base.C1(INDEX_INSERT_SSA, INDEX_INSERT, array_type, array_type);
        this._uelement = new ElemUse().attach_back(this);
    }
    class construct { _istype[TID.INDEX_INSERT_SSA] = true; }

    private sealed class ElemUse: Use {
        public new IndexInsertSSA user {
            get { return static_cast<IndexInsertSSA>(_user); }
        }
        public override Value? usee {
            get { return user._element; }
            set { user.element = value;}
        }
    }
}
