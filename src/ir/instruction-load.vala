/**
 * === 存储单元加载指令 ===
 *
 * 从某个对齐为 `align` 的存储单元中加载类型为 `target_type` 的值.
 */
public class Musys.IR.LoadSSA: UnarySSA {
    [CCode(notify=false)]
    public size_t align{get;set;}

    /** 源操作数的指针类型 */
    public unowned PointerType source_type {
        get { return static_cast<PointerType>(_operand_type); }
    }
    public unowned Type target_type {
        get          { return value_type;   }
        internal set { _value_type = value; }
    }

    public override void accept(IValueVisitor visitor) {
        visitor.visit_inst_load(this);
    }
    public LoadSSA.raw(Type target_type, size_t align = 0) {
        if (!PointerType.IsLegalPointee(target_type)) {
            crash_fmt(SourceLocation.current(),
                "Requires legal pointee type for LoadSSA, but got %s",
                target_type.to_string());
        }
        base.C1(LOAD_SSA, LOAD, target_type,
                target_type.type_ctx.get_opaque_ptr());
        if (align == 0)
            align = target_type.instance_align;
        this.align = align;
    }
    public LoadSSA.from_ptr(Value ptr_value, Type target_type, size_t align = 0) {
        value_ptr_or_crash(ptr_value, "as LoadSSA::from_ptr()::value");
        if (align == 0)
            align = User.get_ptr_value_align(ptr_value);
        if (align == 0)
            align = target_type.instance_align;
        this.raw(target_type, align);
        this.operand = ptr_value;
    }
    public LoadSSA.from_storage(IPointerStorage storage, size_t align = 0)
    {
        if (align == 0)
            align = User.get_ptr_value_align(storage);
        if (align == 0)
            align = storage.get_ptr_target().instance_align;
        this.raw(storage.get_ptr_target(), align);
        this.operand = storage;
    }
}
