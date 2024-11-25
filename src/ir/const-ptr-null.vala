namespace Musys.IR {
    public sealed class ConstPtrNull: ConstExpr, IConstZero {
        public override bool is_zero { get { return true; } }
        public Constant extract_value() { return this; }
        public override void accept (IValueVisitor visitor) {
            visitor.visit_ptr_null (this);
        }

        public uintptr  uint_value { get { return 0; } }
        public ConstInt get_const_int_value(IntType ity) {
            return new ConstInt.from_i64(ity, 0);
        }
        public PointerType ptr_type {
            get { return static_cast<PointerType>(value_type); }
        }

        public ConstPtrNull(PointerType ptr_ty) {
            base.C1(Value.TID.CONST_PTR_NULL, ptr_ty);
        }
        public ConstPtrNull.from_type_ctx(TypeContext tctx) {
            base.C1(Value.TID.CONST_PTR_NULL, tctx.opaque_ptr);
        }
        class construct {
            _istype[TID.ICONST_ZERO]    = true;
            _istype[TID.CONST_PTR_NULL] = true;
            _is_aggregate               = false;
        }
    } // public sealed class ConstPtrNull
}
