namespace Musys.IR {
    /**
     * === 栈内存申请类指令 ===
     *
     * 在当前函数活动的栈帧里申请一段类型为 target_type, 对齐为 align 的存储单元,
     * 并返回其指针.
     *
     * 因为 Musys-IR 的指针量都是不透明的, 所以 `AllocaBase` 及其子类实现了
     * `IPointerValue` 接口用于展示目标类型.
     *
     * @see Musys.IR.IPointerStorage
     *
     * @see Musys.IR.DynAllocaSSA
     *
     * @see Musys.IR.LoadSSA
     *
     * @see Musys.IR.StoreSSA
     */
    public abstract class AllocaBase: Instruction, IPointerStorage {
        public PointerType ptr_type {
            get { return static_cast<PointerType>(value_type); }
        }
        public Type target_type { get; internal set; }
        public Type get_ptr_target() {
            return _target_type;
        }

        public size_t align{get;set;}

        protected AllocaBase.C1(Value.TID tid,  OpCode opcode,
                                Type target_type, size_t align) {
            base.C1 (tid, opcode, target_type.type_ctx.opaque_ptr);
            this.target_type = target_type;
            this.align       = align;
        }
        class construct {
            _istype[TID.ALLOCA_BASE]    = true;
            _istype[TID.IPOINTER_STORAGE] = true;
        }
    }

    /**
     * === 静态栈帧变量存储器申请指令 ===
     *
     * 申请目标类型为 target_type 的 1 单元存储器并返回其指针.
     *
     * - 操作数列表: 无
     *
     * @see Musys.IR.IPointerStorage
     *
     * @see Musys.IR.AllocaSSA
     *
     * @see Musys.IR.LoadSSA
     *
     * @see Musys.IR.StoreSSA
     */
    public class AllocaSSA: AllocaBase {
        public override void accept(IValueVisitor visitor) {
            visitor.visit_inst_alloca(this);
        }

        public AllocaSSA.raw(Type target_type, size_t align = 0) {
            this.from_target(target_type, align);
        }
        public AllocaSSA.from_target(Type target_type, size_t align = 0)
        {
            if (align == 0)
                align = target_type.instance_align;
            base.C1(ALLOCA_SSA, ALLOCA, target_type, align);
        }
        class construct { _istype[TID.ALLOCA_SSA] = true; }
    }

    /**
     * === 动态栈帧变量存储器申请指令 ===
     *
     * 申请目标类型为 target_type、大小有 length 个单元的存储器并返回其指针.
     *
     * ==== 操作数列表 ====
     *
     * - `[0] = length` 表示申请得到的内存可以容纳多少个类型为 target_type 的元素.
     *
     * @see Musys.IR.IPointerStorage
     *
     * @see Musys.IR.LoadSSA
     *
     * @see Musys.IR.StoreSSA
     */
    public class DynAllocaSSA: AllocaBase {
        private Value        _length;
        private unowned Use _ulength;
        public  Value length {
            get { return _length; }
            set {
                if (value == _length)
                    return;
                value_int_or_crash(value, "DynAllocaSSA.length::set()");
                User.set_usee_always(ref _length, value, _ulength);
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

        /**
         * 创建一个类型为 `target_type`, 对齐参数为 `align` 的动态 `alloca` 指令.
         *
         * 该构造函数得到的 `alloca` 指令是''不完备的'', 需要主动给 `length` 赋值.
         */
        public DynAllocaSSA.raw(Type target_type, size_t align = 0) {
            base.C1(DYN_ALLOCA_SSA, DYN_ALLOCA, target_type, align);
            _ulength = new LengthUse().attach_back(this);
        }
        /**
         * 创建一个类型为 `target_type`, 对齐参数为 `align`, 元素个数为 `length`
         * 的动态 `alloca` 指令.
         */
        public DynAllocaSSA.with_length(Type target_type, Value length,
                                        size_t align = 0) {
            this.raw(target_type, align);
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
