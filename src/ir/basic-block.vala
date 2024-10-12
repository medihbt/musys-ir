/**
 * === 基本块 ``BasicBlock`` ===
 *
 * 函数直接管理的指令集, 控制流图结点, 保证执行流顺序进行的最大单位.
 *
 * 完备的基本块是一条指令链表, 其中可以包含以下几种指令:
 *
 * 1. ''Φ 结点 (不一定存在)'': 汇总从入口集合传入的值. 永远处于基本块的开头位置.  
 * Φ 结点的类型是 `PhiSSA`, 在基本块中可以有 0, 1 或若干个.
 *
 * 2. ''普通指令 (不一定存在)'': 除了 Φ 结点和终止子以外的其他指令, 负责处理数据.  
 *
 * 3. ''终止子 (必然存在)'': 表示跳转关系和跳转条件, 维护此基本块的出口集合.
 * __一个完备的基本块''有且只有一个''终止子, 该终止子必须放在基本块的末尾.__
 * 所有终止子都必须实现 `IBasicblockTerminator` 接口.
 *
 * @see Musys.IR.InstructionList
 *
 * @see Musys.IR.Function
 *
 * @see Musys.IR.IBasicBlockTerminator
 */
public class Musys.IR.BasicBlock: Value {
    internal         BasicBlock _next;
    internal unowned BasicBlock _prev;
    internal unowned FuncBody?  _list;

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
    private void _plug_check(BasicBlock before) throws FuncBodyErr
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
    public void plug_this_after(BasicBlock before) throws FuncBodyErr
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
    public void plug_this_before(BasicBlock after) throws FuncBodyErr
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
    /**
     * 自己是否附着在某个函数体内. 附着在函数体内的基本块在控制流的插入/删除
     * 操作内会做特殊处理.
     */
    public bool is_attached { get { return this._list != null; } }

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
    /** ==== 指令列表 ==== */
    public   InstructionList  instructions {
        get { return _instructions; }
    }
    public bool has_terminator() {
        return instructions.length != 0 &&
               instructions.back().isvalue_by_id(IBASIC_BLOCK_TERMINATOR);
    }
    /**
     * ==== 基本块终止子 ====
     * 位于基本块最末尾, 决定控制流方向的指令. 完备的基本块有且只有一个终止子,
     * 但由于优化过程中不时会出现基本块终止子需要替换的情况, 所以这里允许暂时
     * 出现终止子为 null 的情况.
     *
     * 终止子的 set 方法会直接修改最后一条指令. 实际操作取决于 `has_terminator()`
     * 函数的返回值, 可能是插入最后一条指令, 也可能是替换之.
     * @see Musys.IR.IBasicBlockTerminator
     */
    public IBasicBlockTerminator? terminator {
        get {
            return (!has_terminator()) ? null:
                static_cast<IBasicBlockTerminator>(_instructions.back());
        }
        set {
            try { set_terminator_throw(value); }
            catch (Error e) { crash_err(e); }
        }
    }
    /**
     * 基本块终止子的写方法, 遇到错误时会抛异常而不是崩溃.
     * @see Musys.IR.IBasicBlockTerminator
     *
     * @see Musys.IR.BasicBlock.terminator
     */
    public void set_terminator_throw(IBasicBlockTerminator? value)
                throws InstructionListErr {
        assert_nonnull(value);
        if (!has_terminator()) {
            InstructionList.Modifier modif = _instructions.iterator();
            modif.append(value);
            return;
        }
        if (value == _instructions.back())
            return;
        _instructions.back().modifier.replace(value);
    }
    /**
     * 从上到下遍历基本块的指令流, 然后返回第一个不是 PHI 结点的指令.
     * 在完备的 Musys IR 中, PHI 指令永远在基本块指令流的最前面.
     */
    public InstructionList.Iterator get_1st_nonphi()
    {
        foreach (Instruction inst in instructions) {
            if (!(inst is PhiSSA))
                return inst.modifier;
        }
        return {&instructions._node_end};
    }
    /**
     * ==== 附加一条指令 ====
     * 把指令 `inst` 插入指令列表. 倘若指令 `inst` 不是 PHI 结点,
     * 就把 `inst` 附加到指令列表的末尾. 否则, 找到第一条不是 PHI
     * 的指令, 把 `inst` 插入到这条指令的前面.
     */
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
    /** 附加一条 PHI 结点指令. */
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
    }
    public BasicBlock.with_unreachable(LabelType labelty) {
        base.C1(BASIC_BLOCK, labelty);
        _instructions = new InstructionList.empty(this);
        _instructions.append(new UnreachableSSA(this));
        message("Unreachable: refcnt %u\n", _instructions.back().ref_count);
    }
    public BasicBlock.with_terminator(IBasicBlockTerminator terminator)
    {
        var tctx = terminator.value_type.type_ctx;
        base.C1(BASIC_BLOCK, tctx.label_type);
        _instructions = new InstructionList.empty(this);
        _instructions.append(terminator);
    }
    ~BasicBlock() {
        if (instructions == null || instructions.is_empty())
            return;
        foreach (var i in instructions)
            i.on_parent_finalize();
    }
    class construct { _istype[TID.BASIC_BLOCK] = true; }

    /**
     * ==== 基本块的读取迭代闭包 ====
     *
     * 用在遍历函数中, 每次读取一个基本块 bb 并做若干操作. 倘若需要终止迭代,
     * 则返回 true; 否则返回 false.
     *
     * @param bb 等待读取的基本块
     *
     * @return 是 (true) 或否 (false) 终止迭代. 不清楚怎么返回的话, 写 false
     *         一般没错.
     */
    [CCode(cname="_ZN5Musys2IR10BasicBlock8ReadFuncE")]
    public delegate bool ReadFunc(BasicBlock bb);

    /**
     * ==== 基本块替换迭代闭包 ====
     *
     * 用在遍历函数中, 每次读取一个基本块 bb, 执行若干操作并决定怎么替换这个
     * 基本块 bb. 倘若需要终止迭代, 就返回 null; 倘若替换原基本块, 则返回与
     * 参数 bb 相同的值; 倘若要做替换, 则返回你需要的值.
     *
     * 做完替换以后, 遍历函数会继续遍历. 如果你需要在替换后终止遍历, 就在下一轮
     * 执行该函数时返回 null.
     *
     * @param bb 等待读取的基本块.
     *
     * @return 返回 null 表示终止遍历, 返回 bb 自己表示不做替换继续遍历, 返回
     *         其他值表示做替换并继续遍历.
     */
    [CCode(cname="_ZN5Musys2IR10BasicBlock11ReplaceFuncE")]
    public delegate BasicBlock? ReplaceFunc(BasicBlock bb);
}
