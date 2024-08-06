public class Musys.IR.BasicBlock: Value {
    internal         BasicBlock _next;
    internal unowned BasicBlock _prev;
    internal unowned FuncBody   _list;

    public BasicBlock unplug()
    {
        BasicBlock othis = this;
        BasicBlock next  = othis._next;
        BasicBlock prev  = othis._prev;
        prev._next = next; next._prev = prev;
        _list.length--;
        this._next = null; this._prev = null;
        this._list = null;
        return othis;
    }
    private inline void _plug_check(BasicBlock before)
    {
        if (this == before)
            crash("DO NOT plug this basic block after itself\n");
        if (this._list != null) {
            crash("DO NOT plug this basic block if it's already plugged (to %p, function %s)"
                 .printf(_list, _list.parent.name));
        }
        unowned var list = before._list;
        if (before._list == null) {
            crash("DO NOT plug this basic block (%p) after/before an UNCONNECTED block (%p)"
                 .printf(this, before));
        }
    }
    public void plug_this_after(BasicBlock before)
    {
        _plug_check(before);
        unowned var list = before._list;
        if (before == list._node_end || before._next == null) {
            crash("Node(%p) at the end of the list is NOT ACCESSIBLE. DO NOT insert this(%p) at its next\n"
                 .printf(before, this));
        }
        BasicBlock next = before._next, prev = before;
        this._next = next; this._prev = prev;
        prev._next = this; next._prev = this;
        this._list = list; this.parent = before.parent;
        list.length++;
    }
    public void plug_this_before(BasicBlock after)
    {
        _plug_check(after);
        unowned var list = after._list;
        if (after == list._node_begin || after._prev == null) {
            crash("Node(%p) at the begin of the list is NOT ACCESSIBLE. DO NOT insert this(%p) at its front\n"
                 .printf(after, this));
        }
        BasicBlock next = after, prev = after._prev;
        this._next = next; this._prev = prev;
        prev._next = this; next._prev = this;
        this._list = list; this.parent = after.parent;
        list.length++;
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
    internal BasicBlock.raw(LabelType labelty) {
        base.C1(BASIC_BLOCK, labelty);
        _instructions = null;
    }
    public BasicBlock.with_unreachable(LabelType labelty) {
        base.C1(BASIC_BLOCK, labelty);
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
