namespace Musys.IR {
    /**
     * ### 常量
     * 
     * 存储不变量或者全局量的值。有时常量会引用其他值，所以常量都是 User.
     */
    public abstract class Constant: User {
        /** 自己能不能确定自己是常量 0. */
        public abstract bool is_zero{get;}

        protected Constant.C1(Value.TID tid, Type type) {
            base.C1(tid, type);
        }
        class construct { _istype[TID.CONSTANT] = true; }

        private static Constant? _create_zero_impl(Type type) throws TypeMismatchErr
        {
            if (type.is_int)
                return new ConstInt.from_i64(static_cast<IntType>(type), 0);
            if (type.is_float)
                return new ConstFloat.from_f64(static_cast<FloatType>(type), 0);
            if (type.is_valuetype)
                return new ConstDataZero(static_cast<PrimitiveType>(type));
            if (type.is_aggregate)
                return create_const_aggregate_zero(static_cast<AggregateType>(type));
            if (type.is_pointer)
                return new ConstPtrNull(static_cast<PointerType>(type));
            return null;
        }

        public static Constant CreateZero(Type type) throws TypeMismatchErr
        {
            Constant? ret = _create_zero_impl(type);
            if (ret != null)
                return ret;
            if (!type.is_instantaneous)
                throw new TypeMismatchErr.NOT_INSTANTANEOUS("type %s not instantaneous", type.to_string());
            throw new TypeMismatchErr.MISMATCH(type.to_string());
        }

        public static Constant CreateZeroOrUndefined(Type type)
        {
            try {
                return _create_zero_impl(type) ?? new UndefinedValue(type, false);
            } catch (TypeMismatchErr e) {
                critical("Encountered type mismatch: %s!", e.message);
                traced_abort();
            }
        }
    }

    /** 编译期必然是常量的值. */
    public interface IConstZero: Constant {
        public abstract Constant extract_value();
    }

    [Version(deprecated=true)]
    public Constant create_const_zero(Type type) throws TypeMismatchErr {
        return Constant.CreateZero(type);
    }

    [Version(deprecated=true)]
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
