namespace Musys.IR {
    public class StoreSSA: Instruction {
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
            source = null;  target = null;
        }
        public override void on_function_finalize() {
            _source = null; _target = null;
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
            _usrc = new StoreSrcUse(this).attach_back(this);
            _udst = new StoreDstUse(this).attach_back(this);
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
    }

    [CCode(cname="_ZN5Musys2IR11StoreSrcUseE")]
    private sealed class StoreSrcUse: Use {
        public new StoreSSA user {
            get { return static_cast<StoreSSA>(_user); }
        }
        public override Value? usee {
            get { return user.source; } set { user.source = value; }
        }
        [CCode(cname="_ZN5Musys2IR11StoreSrcUseC2E")]
        public StoreSrcUse(StoreSSA user) { base.C1(user); }
    }
    [CCode(cname="_ZN5Musys2IR11StoreDstUseE")]
    private sealed class StoreDstUse: Use {
        public new StoreSSA user {
            get { return static_cast<StoreSSA>(_user); }
        }
        public override Value? usee {
            get { return user.target; } set { user.target = value; }
        }
        [CCode(cname="_ZN5Musys2IR11StoreDstUseC2E")]
        public StoreDstUse(StoreSSA user) { base.C1(user); }
    }
}
