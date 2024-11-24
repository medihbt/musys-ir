namespace Musys.IR {
    public abstract class ConstData: Constant {
        [CCode(notify=false)]
        public abstract int64  i64_value{get;set;}

        [CCode(notify=false)]
        public virtual  uint64 u64_value {
            get { return i64_value; } set { i64_value = (int64)value; }
        }

        [CCode(notify=false)]
        public abstract double f64_value{get;set;}

        public new PrimitiveType value_type {
            get { return static_cast<PrimitiveType>(value_type); }
        }

        public ConstData clone() { return _clone_impl(); }
        protected abstract ConstData _clone_impl();

        protected ConstData.C1(Value.TID tid, PrimitiveType type) {
            base.C1(tid, type);
        }
        class construct {
            _istype[TID.CONST_DATA] = true;
            _shares_ref             = true;
        }
    }

    public class ConstDataZero: ConstData, IConstZero {
        public Constant extract_value()
        {
            if (value_type.is_int)
                return new ConstInt.from_i64((IntType)value_type, 0);
            if (value_type.is_float)
                return new ConstFloat.from_f64((FloatType)value_type, 0.0);
            assert_not_reached();
        }

        public override bool   is_zero   { get { return true; } }
        [CCode(notify=false)]
        public override int64  i64_value { get { return 0; } set{} }
        [CCode(notify=false)]
        public override uint64 u64_value { get { return 0; } set{} }
        [CCode(notify=false)]
        public override double f64_value { get { return 0; } set{} }
        public override void accept(IValueVisitor visitor) {
            visitor.visit_const_data_zero(this);
        }

        public new ConstDataZero clone() {
            return new ConstDataZero(value_type);
        }
        protected override ConstData _clone_impl() {
            return this.clone();
        }

        public ConstDataZero(PrimitiveType value_type) {
            base.C1(Value.TID.CONST_DATA_ZERO, value_type);
        }
        class construct {
            _istype[TID.ICONST_ZERO]     = true;
            _istype[TID.CONST_DATA_ZERO] = true;
        }
    }

    public class ConstInt: ConstData {
        [CCode (notify=false)]
        public APInt apint_value {get;set;}

        public IntType int_type { get { return static_cast<IntType>(_value_type); } }

        public override double f64_value {
            get{ return i64_value; } set{ i64_value = (int64)value; }
        }
        public override int64  i64_value {
            get { return _apint_value.i64_value; }
            set { _apint_value.i64_value = value; }
        }
        public override uint64 u64_value {
            get { return _apint_value.u64_value;  }
            set { _apint_value.u64_value = value; }
        }

        public override bool is_zero {
            get { return apint_value.data == 0; }
        }
        public override void accept(IValueVisitor visitor) {
            visitor.visit_const_int(this);
        }

        public new ConstInt clone() {
            return new ConstInt.from_i64(int_type, i64_value);
        }
        protected override ConstData _clone_impl() {
            return clone();
        }

        public ConstInt.from_i64(IntType ity, int64 i64_value)
        {
            base.C1(CONST_INT, ity);
            this._apint_value = APInt.from_i64(i64_value, (uint8)ity.binary_bits);
        }
        class construct { _istype[TID.CONST_INT] = true; }
    }

    public class ConstFloat: ConstData {
        public FloatType float_type { get { return static_cast<FloatType>(_value_type); } }

        public override bool   is_zero   { get { return f64_value == 0.0; } }

        [CCode(notify=false)]
        public override double f64_value { get; set; }

        [CCode(notify=false)]
        public override int64  i64_value {
            get{ return (int64)_f64_value;  } set { _f64_value = value; }
        }
        [CCode(notify=false)]
        public override uint64 u64_value {
            get{ return (uint64)_f64_value; } set { _f64_value = value; }
        }
        public override void accept(IValueVisitor visitor) {
            visitor.visit_const_float(this);
        }

        public new ConstFloat clone() {
            return new ConstFloat.from_f64(float_type, f64_value);
        }
        protected override ConstData _clone_impl() {
            return clone();
        }

        public ConstFloat.from_f64(FloatType fty, double value) {
            base.C1(CONST_FLOAT, fty);
            this._f64_value = value;
        }
        class construct { _istype[TID.CONST_FLOAT] = true; }
    }
}
