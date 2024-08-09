namespace Musys.IR {
    public sealed class ArrayExpr: ConstExpr {
        public  ArrayType array_type {
            get { return static_cast<ArrayType>(_value_type); }
        }
        internal Constant []_elems;

        [CCode(notify=false)]
        public   Constant []elems {
            get {
                if (_elems != null)
                    return _elems;
                _elems = new Constant[array_type.element_number];
                for (int i = 0; i < _elems.length; i++)
                    _elems[i] = create_zero_or_undefined(array_type.element_type);
                return _elems;
            }
        }

        public override bool is_zero {
            get {
                if (_elems == null || _elems.length == 0)
                    return true;
                foreach (var i in _elems) {
                    if (!i.is_zero)
                        return false;
                }
                return true;
            }
        }
        public override void accept (IValueVisitor visitor) {
            visitor.visit_array_expr (this);
        }

        public ArrayExpr.empty(ArrayType arr_ty) {
            base.C1 (ARRAY_EXPR, arr_ty);
            this._value_type = arr_ty;
            this._elems      = null;
        }
        class construct { _istype[TID.ARRAY_EXPR] = true; }
    }
}