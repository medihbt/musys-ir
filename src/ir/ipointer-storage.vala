/**
 * === 存储单元 ===
 *
 * 标识一个值的类型必然是指针, 并且必然存储一个值. 也就是说, 倘若某个 Value
 * 子类的类型一定是指针类型并且不是 null, 那它就要实现这个接口.
 *
 * **可能要实现的方法**:
 *
 * - `get_ptr_target() abstract`: 返回该指针量指向的对象应当具有的类型.
 * - `fits_target(Type) virtual`: 类型 target 是否可以作为该指针量的子类型.
 */
public interface Musys.IR.IPointerStorage: Value {
    /** 存储单元的权限信息, 包括读写/执行. */
    [Flags]
    public enum Permission {
        /** 可读: 可以通过 load 指令从存储器取值 */
        READ,
        /** 可写: 可以通过 store 指令把值存储到存储器内 */
        WRITE,
        /**
         * 可执行: 可以通过 call/vcall/invoke 等指令
         * 把这个值当成函数指针执行
         */
        EXEC,
        UNDEFINED;
        public static Permission None() {
            return 0;
        }
        public static Permission ReadWrite() {
            return READ | WRITE;
        }
        public static Permission AsFunction() {
            return READ | EXEC;
        }
        public bool defined()    { return (this & UNDEFINED) == 0; }
        public bool readable()   { return (this & READ)  != 0; }
        public bool writable()   { return (this & WRITE) != 0; }
        public bool executable() { return (this & EXEC)  != 0; }
        public bool meets_accessor(Permission accessor) {
            return (accessor & (~this)) == 0;
        }
    }

    /** 返回该指针量指向的对象应当具有的类型. */
    public abstract Type get_ptr_target();

    /** 类型 target 是否可以作为该指针量的子类型. */
    public virtual bool fits_target(Type target)
    {
        Type ptr_target = get_ptr_target();
        if (ptr_target.is_void)
            return PointerType.IsLegalPointee(ptr_target);
        return ptr_target.equals(target);
    }

    /** 返回自己是不是一个合法的指针量. 该函数是保险用的. */
    public bool self_is_legal_storage() {
        return this.value_type.istype_by_id(OPAQUE_PTR_TYPE);
    }

    public static Type? GetDirectTarget(Value value)
    {
        var value_type = value.value_type;
        if (!value_type.istype_by_id(OPAQUE_PTR_TYPE))
            return null;
        if (value is IPointerStorage)
            return static_cast<IPointerStorage>(value).get_ptr_target();
        return value_type.type_ctx.void_type;
    }
}
