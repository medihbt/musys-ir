namespace Musys.IR {
    public abstract class Constant: User {
        public abstract bool is_zero{get;}
        protected Constant.C1(Value.TID tid, Type type) {
            base.C1(tid, type);
        }
        class construct { _istype[TID.CONSTANT] = true; }
    }

    public interface IConstZero: Constant {
        public abstract Constant extract_value();
    }

    public Constant create_const_zero(Type type) throws TypeMismatchErr
    {
        if (type.is_int)
            return new ConstInt.from_i64(static_cast<IntType>(type), 0);
        if (type.is_float)
            return new ConstFloat.from_f64(static_cast<FloatType>(type), 0);
        if (type.is_valuetype)
            return new ConstDataZero(static_cast<ValueType>(type));
        if (type.is_aggregate)
            return create_const_aggregate_zero(static_cast<AggregateType>(type));
        if (type.is_pointer)
            return new ConstPtrNull(static_cast<PointerType>(type));
        throw new TypeMismatchErr.NOT_INSTANTANEOUS(type.to_string());
    }
    public Constant create_zero_or_undefined(Type type)
    {
        try {
            return create_const_zero(type);
        } catch (TypeMismatchErr.NOT_INSTANTANEOUS e) {
            return new UndefinedValue(type, false);
        } catch (TypeMismatchErr e) {
            crash("TypeMismatchErr: msg %s".printf(e.message));
        }
    }
}
