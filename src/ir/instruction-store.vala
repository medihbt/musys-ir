public class Musys.IR.StoreSSA: Instruction {
    private Value _source;
    private Value _target;
    private unowned Use _usrc;
    private unowned Use _udst;
    public Value source {
        get { return _source; }
        set { set_usee_type_match(_srcty, ref _source, value, _usrc); }
    }
    public Value target {
        get { return _target; }
        set { set_usee_type_match(_dstty, ref _target, value, _udst); }
    }
    
    private unowned Type        _srcty;
    private unowned PointerType _dstty;
    public Type        source_type { get { return _srcty; } }
    public PointerType target_type { get { return _dstty; } }

    [CCode(notify=false)]
    public size_t align{get;set;}

    public override void on_parent_finalize() {
        value_deep_clean(ref _source, _usrc);
        value_deep_clean(ref _target, _udst);
        base._deep_clean();
    }
    public override void on_function_finalize() {
        value_fast_clean(ref _source, _usrc);
        value_fast_clean(ref _target, _udst);
        base._fast_clean();
    }
    public override void accept(IValueVisitor visitor) {
        visitor.visit_inst_store(this);
    }

    public StoreSSA.raw(PointerType target_type, size_t align) {
        unowned var tctx = target_type.type_ctx;
        unowned var voidty = tctx.void_type;
        base.C1(STORE_SSA, STORE, voidty);
        _srcty = target_type.target;
        _dstty = target_type;
        _usrc = new SrcUse(this).attach_back(this);
        _udst = new DstUse(this).attach_back(this);
        this.align = align;
    }
    public StoreSSA.from(Value src, Value dst, size_t align = 0) {
        PointerType pty = value_ptr_or_crash(dst, "at StoreSSA()::dst");
        if (align == 0)
            align = User.get_ptr_value_align(dst);
        this.raw(pty, align);
        this.target = dst;
        this.source = src;
    }
    public StoreSSA.from_load(Value src, LoadSSA dst) {
        this.raw(dst.source_type, dst.align);
        this.target = dst;
        this.source = src;
    }
    class construct { _istype[TID.STORE_SSA] = true; }

    private sealed class SrcUse: Use {
        public new StoreSSA user {
            get { return static_cast<StoreSSA>(_user); }
        }
        public override Value? usee {
            get { return user.source; } set { user.source = value; }
        }
        [CCode(cname="_ZN5Musys2IR5Store6SrcUseC2E")]
        public SrcUse(StoreSSA user) { base.C1(user); }
    }
    private sealed class DstUse: Use {
        public new StoreSSA user {
            get { return static_cast<StoreSSA>(_user); }
        }
        public override Value? usee {
            get { return user.target; } set { user.target = value; }
        }
        [CCode(cname="_ZN5Musys2IR5Store6DstUseC2E")]
        public DstUse(StoreSSA user) { base.C1(user); }
    }
}
