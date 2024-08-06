public class Musys.IR.BasicBlock: Value {
    internal         BasicBlock _next;
    internal unowned BasicBlock _prev;
    internal unowned FuncBody   _list;

    public BasicBlock unplug()
    {
        BasicBlock othis = this;
        _prev._next = _next;
        _next._prev = _prev;
        _list.length--;
        return othis;
    }
    public void on_function_finalize()
    {
        if (instructions == null)
            return;
        foreach (var i in instructions)
            i.on_function_finalize();
        instructions.clean();
    }

    public weak Function parent{get;set;}

    internal InstructionList _instructions;
    public   InstructionList  instructions {
        get { return _instructions; }
    }
    public IBasicBlockTerminator terminator{get;set;}
    public InstructionList.Iterator append(Instruction inst) throws InstructionListErr
    {
        if (inst is IBasicBlockTerminator) {
            var opcode = inst.opcode;
            unowned var iklass = inst.get_class();
            crash("instruction cannot be terminator, but got %p(class %s, opcode %s)\n"
                 .printf(inst, iklass.get_name(), opcode.to_string()));
        }
        terminator.modifier.prepend(inst);
        return inst.modifier;
    }

    public override void accept(IValueVisitor visitor) {
        visitor.visit_basicblock (this);
    }
    internal BasicBlock.raw(TypeContext tctx) {
        base.C1(BASIC_BLOCK, tctx.label_type);
        _instructions = null;
    }
    public BasicBlock.with_unreachable(TypeContext tctx) {
        base.C1(BASIC_BLOCK, tctx.label_type);
        _instructions = new InstructionList.empty(this);
        _instructions.append(
            new UnreachableSSA(this)
        );
    }
    public BasicBlock.with_terminator(owned IBasicBlockTerminator terminator)
    {
        var tctx = terminator.value_type.type_ctx;
        base.C1(BASIC_BLOCK, tctx.label_type);
        _instructions = new InstructionList.empty(this);
        _instructions.append(terminator);
        this.terminator = terminator;
    }
    ~BasicBlock() {
        if (instructions == null || instructions.is_empty())
            return;
        foreach (var i in instructions)
            i.on_parent_finalize();
        instructions.clean();
    }
    class construct { _istype[TID.BASIC_BLOCK] = true; }

    [CCode(cname="_ZN5Musys2IR10BasicBlock8ReadFuncE")]
    public delegate bool        ReadFunc   (BasicBlock value);

    [CCode(cname="_ZN5Musys2IR10BasicBlock11ReplaceFuncE")]
    public delegate BasicBlock? ReplaceFunc(BasicBlock value);
}
