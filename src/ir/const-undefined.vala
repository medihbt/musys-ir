namespace Musys.IR {
    public class UndefinedValue: Constant {
        public bool is_poisonous { get; set; default = false; }

        public override bool is_zero { get { return false; } }
        public override void accept (IValueVisitor visitor) {
            visitor.visit_undefined (this);
        }

        public UndefinedValue(Type type, bool is_poisonous) {
            base.C1(CONST_UNDEFINED, type);
            this._is_poisonous = is_poisonous;
        }
        class construct {
            _istype[TID.CONST_UNDEFINED] = true;
            _shares_ref                  = true;
        }
    }
}