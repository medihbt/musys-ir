/**
 * === 基本块 `BasicBlock` ===
 *
 * 函数直接管理的指令集, 控制流图结点, 保证执行流顺序进行的最大单位.
 *
 * 完备的基本块是一条指令链表, 其中可以包含以下几种指令:
 *
 * - ''Φ 结点 (不一定存在)'': 汇总从入口集合传入的值. 永远处于基本块的开头位置.
 *   Φ 结点的类型是 `PhiSSA`, 在基本块中可以有 0, 1 或若干个.
 * - ''普通指令 (不一定存在)'': 除了 Φ 结点和终止子以外的其他指令, 负责处理数据.
 * - ''终止子 (必然存在)'': 表示跳转关系和跳转条件, 维护此基本块的出口集合.
 *   __一个完备的基本块''有且只有一个''终止子, 该终止子必须放在基本块的末尾.__
 *   所有终止子都必须实现 `IBasicblockTerminator` 接口.
 *
 * @see Musys.IR.InstructionList
 *
 * @see Musys.IR.Function
 */
public class Musys.IR.BasicBlock: Value {
    internal         BasicBlock _next;
    internal unowned BasicBlock _prev;
    internal unowned FuncBody   _list;

    /**
     * 把自己从所在的函数体上取下来, 然后返回(带所有权的自己).
     *
     * 该方法''不会检查''控制流关系或数据流关系, 不会检查这个基本块是不是函数的入口,
     * 也不会自动维护控制流/数据流. 倘若调用者调用该方法的目的是删除该基本块,
     * 那要么保证这个基本块和其他基本块的联系都断开了, 要么做好清理控制流、数据流
     * 等善后工作. 同时, ''必须保证这个基本块不是入口''.
     *
     * 该方法会自动维护该基本块所在的函数体的长度等信息, 因此不用担心长度等数据
     * 出错了.
     *
     * @return 带所有权的自己. 这么做是为了防止函数返回时自己就被析构了.
     */
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

    /** 展示自己的标签类型. 这是为了方便从其他基本块构造而写的. */
    public LabelType show_label_type() {
        return (!)(value_type as LabelType);
    }

    /** 中间代码结点树的父结点 -- 函数. */
    public unowned Function parent{get;set;}

    internal InstructionList _instructions;
    public   InstructionList  instructions {
        get { return _instructions; }
    }
    public bool has_terminator() {
        return instructions.length != 0 &&
               instructions.back().isvalue_by_id(IBASIC_BLOCK_TERMINATOR);
    }
    public unowned IBasicBlockTerminator? terminator {
        get {
            return (!has_terminator()) ? null:
                static_cast<IBasicBlockTerminator>(_instructions.back());
        }
        set {
            (!)value;
            try {
                if (!has_terminator()) {
                    InstructionList.Modifier modif = _instructions.iterator();
                    modif.append(value);
                    return;
                }
                if (value == _instructions.back())
                    return;
                _instructions.back().modifier.replace(value);
            } catch (Error e) {
                crash(e.message);
            }
        }
    }
    public InstructionList.Iterator get_1st_nonphi()
    {
        foreach (Instruction inst in instructions) {
            if (!(inst is PhiSSA))
                return inst.modifier;
        }
        return {&instructions._node_end};
    }
    public InstructionList.Iterator append(Instruction inst)
            throws InstructionListErr
    {
        if (inst is PhiSSA)
            return append_phi(static_cast<PhiSSA>(inst));
        if (inst is IBasicBlockTerminator) {
            var opcode = inst.opcode;
            unowned var iklass = inst.get_class();
            crash("instruction cannot be terminator, but got %p(class %s, opcode %s)\n"
                 .printf(inst, iklass.get_name(), opcode.to_string()));
        }
        terminator.modifier.prepend(inst);
        return inst.modifier;
    }
    public InstructionList.Iterator append_phi(PhiSSA phi)
            throws InstructionListErr {
        InstructionList.Modifier m = get_1st_nonphi();
        return m.prepend(phi);
    }

    public override void accept(IValueVisitor visitor) {
        visitor.visit_basicblock (this);
    }
    public BasicBlock.raw(LabelType labelty) {
        base.C1(BASIC_BLOCK, labelty);
        _instructions = null;
    }
    public BasicBlock.with_unreachable(LabelType labelty) {
        base.C1(BASIC_BLOCK, labelty);
        _instructions = new InstructionList.empty(this);
        _instructions.append(
            new UnreachableSSA(this)
        );
        print("Unreachable: refcnt %u\n", _instructions.back().ref_count);
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
    }
    class construct { _istype[TID.BASIC_BLOCK] = true; }

    [CCode(cname="_ZN5Musys2IR10BasicBlock8ReadFuncE")]
    public delegate bool        ReadFunc   (BasicBlock value);

    [CCode(cname="_ZN5Musys2IR10BasicBlock11ReplaceFuncE")]
    public delegate BasicBlock? ReplaceFunc(BasicBlock value);
}
