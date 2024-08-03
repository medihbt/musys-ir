namespace Musys.IR {
    public class PhiFromUse: Use {
        public unowned PhiSSA parent {
            get { return static_cast<PhiSSA>(_user); }
        }
        public unowned BasicBlock from;
        internal       Value  _operand;
        public inline  Type value_type { get { return parent.value_type; } }
        public override Value? usee {
            get { return _operand; }
            set {
                if (value == null) do_clean_operand();
                set_operand(value);
            }
        }
        public override Use remove_operand() { return do_clean_operand(); }
        internal inline void set_operand(Value value) {
            type_match_or_crash(value_type, value.value_type);
            User.replace_use(_operand, value, this);
            _operand = value;
        }
        internal inline Use do_clean_operand()
        {
            if (_operand != null)
                _operand.remove_use_as_usee(this);
            PhiFromUse othis = this;
            parent.from_map.unset(from, out othis);
            remove_this();
            return othis;
        }
    }

    public errordomain PhiError {
        NO_INCOMING_BLOCK;
    }
    public class PhiSSA: Instruction {
        public Gee.HashMap<unowned BasicBlock, PhiFromUse> from_map{get;}
        public new PhiFromUse get_use(BasicBlock index) throws PhiError {
            if (!from_map.has_key(index))
                throw new PhiError.NO_INCOMING_BLOCK("phi %p, index %p".printf(this, index));
            return from_map.get(index);
        }

        public override void on_parent_finalize() {
            assert_not_reached ();
        }
        public override void accept(IValueVisitor visitor) {
            visitor.visit_inst_phi(this);
        }

        public PhiSSA.raw(Type type) {
            base.C1(PHI_SSA, PHI, type);
            this._from_map = new Gee.HashMap<unowned BasicBlock, PhiFromUse>();
        }
    }
}
