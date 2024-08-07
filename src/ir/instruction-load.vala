public class Musys.IR.LoadSSA: UnarySSA {
    [CCode(notify=false)]
    public size_t align{get;set;}
    public PointerType source_type {
        get { return static_cast<PointerType>(_operand_type); }
    }

    public override void accept(IValueVisitor visitor) {
        visitor.visit_inst_load(this);
    }
    public LoadSSA.raw(PointerType type, size_t align) {
        base.C1(LOAD_SSA, LOAD, type.target, type);
        this._align = align;
    }
    public LoadSSA.from_ptr(Value ptr_value, size_t align = 0) {
        var pty = value_ptr_or_crash(ptr_value, "as LoadSSA::from_ptr()::value");
        if (align == 0)
            align = User.get_ptr_value_align(ptr_value);
        this.raw(pty, align);
        this.operand = ptr_value;
    }
}
