namespace Musys.IR {
    public abstract class AllocaBase: Instruction {
        public PointerType ptr_type {
            get { return static_cast<PointerType>(value_type); }
        }
        public Type target_type {
            get { return ptr_type.target; }
        }
        public size_t align{get;set;}

        protected AllocaBase.C1(Value.TID   tid,  OpCode opcode,
                                PointerType type, size_t align) {
            base.C1 (tid, opcode, type);
        }
        class construct { _istype[TID.ALLOCA_BASE] = true; }
    }

    public class AllocaSSA: AllocaBase {
        public override void accept(IValueVisitor visitor) {
            visitor.visit_inst_alloca(this);
        }

        public AllocaSSA.raw(PointerType type, size_t align = 0)
        {
            if (align == 0)
                align = type.target.instance_align;
            base.C1(ALLOCA_SSA, ALLOCA, type, align);
        }
        public AllocaSSA.from_target(Type target_type, size_t align = 0)
        {
            var tctx = target_type.type_ctx;
            var pty = tctx.get_ptr_type(target_type);
            this.raw(pty, align);
        }
        class construct { _istype[TID.ALLOCA_SSA] = true; }
    }

    public class DynAllocaSSA: AllocaBase {
        private Value        _length;
        private unowned Use _ulength;
        public  Value length {
            get { return _length; }
            set {
                if (value == _length)
                    return;
                value_int_or_crash(value, "at DynAllocaSSA.length::set()");
                replace_use(_length, value, _ulength);
                _length = value;
            }
        }

        public override void on_parent_finalize() {
            length = null;  base._deep_clean();
        }
        public override void on_function_finalize() {
            _length = null; base._deep_clean();
        }
        public override void accept(IValueVisitor visitor) {
            visitor.visit_inst_dyn_alloca(this);
        }
        
        public DynAllocaSSA.raw(PointerType type, size_t align = 0) {
            if (align == 0)
                align = type.target.instance_align;
            base.C1(DYN_ALLOCA_SSA, DYN_ALLOCA, type, align);
            _ulength = new LengthUse().attach_back(this);
        }
        public DynAllocaSSA.with_length(Value length, size_t align = 0) {
            PointerType pty = value_ptr_or_crash(
                    length, "at DynAllocaSSA::with_length()::length");
            this.raw(pty, align);
            this.length = length;
        }
        class construct { _istype[TID.DYN_ALLOCA_SSA] = true; }

        private sealed class LengthUse: Use {
            public new DynAllocaSSA user {
                get { return static_cast<DynAllocaSSA>(_user); }
            }
            public override Value? usee {
                get { return user.length; } set { user.length = value; }
            }
        }
    }
}
