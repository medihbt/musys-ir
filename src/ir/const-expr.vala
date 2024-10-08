namespace Musys.IR {
    public abstract class ConstExpr: Constant {
        public bool is_aggregate { get { return _is_aggregate; } }
        
        protected ConstExpr.C1(Value.TID tid, Type type) {
            base.C1(tid, type);
        }
    /* ================ [class-shared data] ================ */
        protected class stdc.bool _is_aggregate = true;
        class construct {
            _istype[TID.CONST_EXPR] = true;
            _shares_ref             = true;
        }
    }

    public ConstExpr create_const_aggregate_zero(AggregateType type)
                     throws TypeMismatchErr
    {
        if (type.is_array)
            return new ArrayExpr.empty(static_cast<ArrayType>(type));
        if (type.is_struct)
            return new StructExpr.empty(static_cast<StructType>(type));
        throw new TypeMismatchErr.NOT_AGGREGATE(@"Type $type is not array type or struct type");
    }
}
