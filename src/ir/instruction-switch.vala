/**
 * === 多分支跳转指令 ===
 *
 * 根据整数条件 condition, 在分支跳转表 cases 中找到相等的目标基本块并跳转过去.
 * 倘若分支跳转表中不存在对应的分支, 则跳转到默认分支 default_target.
 *
 * ==== 操作数表 ====
 *
 * switch 指令只有一个操作数 condition. 分支跳转表里的那些基本块不是作为数据参与
 * 运算的, 因此不算操作数.
 *
 * * ``[0] = condition``: 整数条件.
 *
 * ==== 文本格式 ====
 *
 * 一条 switch 指令就要占掉不止一行, 这在 Musys IR 中是少有的.
 *
 * {{{
 * switch <int type> <condition>, label <default target>, [
 *     i64 <case 1>, label %<target 1>
 *     i64 <case 2>, label %<target 2>
 *     ...
 * ]
 * }}}
 *
 * SwitchSSA 保证在遍历时条件总是从小到大排序的. 因此, 该实现内部采用有序树存储跳转条件.
 */
public class Musys.IR.SwitchSSA: JumpBase {
    public GLib.Tree<long, CaseTarget> cases {
        get; internal set;
        default = new Tree<long, CaseTarget>(longcmp);
    }

    /** GTree 不能使用 foreach 语法遍历, 这里是做了一层很薄的封装. ''非 Vala 语言不要调用这个函数''. */
    public CaseTreeView view_cases() { return { cases }; }

    public CaseTarget? get_case(long case_n) { return cases.lookup(case_n); }

    public void set_case(long case_n, BasicBlock bb)
    {
        unowned var node = cases.lookup_node(case_n);
        if (node == null) {
            if (bb == null)
                return;
            var case_t = new CaseTarget() { target = bb, order = case_n };
            node = cases.insert_node(case_n, case_t);
            unowned var? prev = node.previous();
            case_t.attach_after_node(prev == null? this._default_target: prev.value());
        } else {
            node.value().target = bb;
        }
    }
    public bool remove_case(long case_n)
    {
        CaseTarget? value = cases.lookup(case_n);
        if (value == null)
            return false;
        value.unplug();
        return cases.remove(case_n);
    }

    public CaseTarget? find_case(BasicBlock target) {
        foreach (CaseTarget ct in view_cases()) {
            if (ct.target == target)
                return ct;
        }
        return null;
    }

    private Value _condition;
    private Use  _ucondition;
    public Value condition {
        get { return _condition; }
        set {
            value_int_or_crash(value, "SwitchSSA(%p).condition::set", this);
            User.set_usee_always(ref _condition, value, _ucondition);
        }
    }
    public override void accept(IValueVisitor visitor) {
        visitor.visit_inst_switch(this);
    }
    public override void on_parent_finalize() {
        default_target = null;
        cases.remove_all();
        base._deep_clean();
    }
    public override void on_function_finalize() {
        default_target = null;
        cases.remove_all();
        base._deep_clean();
    }

    public SwitchSSA.raw(VoidType voidty) {
        base.C1(TID.SWITCH_SSA, OpCode.SWITCH, voidty);
        this._ucondition = new CondUse().attach_back(this);
    }
    public SwitchSSA.with_default(Value condition, BasicBlock default_target) {
        this.raw(default_target.value_type.type_ctx.void_type);
        this.default_target = default_target;
        this.condition = condition;
    }
    public SwitchSSA.ordered(Value condition, BasicBlock default_target,
                             BasicBlock[] bbs, OrderParam param = OrderParam.DEFAULT) {
        this.with_default(condition, default_target);
        long case_n = param.start_case;
        foreach (var bb in bbs) {
            if (bb != default_target || param.contains_default)
                this.set_case(case_n, bb);
            case_n += param.case_step;
        }
    }
    public SwitchSSA.from(Value condition, BasicBlock default_target, Gee.Traversable<CaseTarget> cases) {
        this.with_default(condition, default_target);
        cases.foreach((c) => {
            if (c.bb != default_target)
                this.set_case(c.case_n, c.bb);
            return true;
        });
    }
    class construct { _istype[TID.SWITCH_SSA] = true; }

    /** Switch 的条件分支 */
    public class CaseTarget: JumpTarget {
        public long case_n {
            get { return this.order; }
            internal set { this.order = value; }
        }
        public unowned BasicBlock bb {
            get { return target; } set { target = value; }
        }
        public CaseTarget() { base(SWITCH_CASE); }
        public CaseTarget.from(SwitchSSA parent, BasicBlock bb, long case_n) {
            base(SWITCH_CASE);
            this.attach_back(parent.jump_targets);
            this.target = bb; this.case_n = case_n;
        }
    }
    public struct OrderParam {
        long start_case;
        long case_step;
        bool contains_default;

        public const OrderParam DEFAULT = { 0, 1, true };
    }

    private sealed class CondUse: Use {
        public new SwitchSSA user {
            get { return static_cast<SwitchSSA>(_user); }
        }
        public override Value? usee {
            get { return user.condition; }
            set { user.condition = value; }
        }
    } // sealed class CondUse

    /** cases 树集合的简单封装, 实现了 GTree 没有的 foreach 遍历功能. */
    public struct CaseTreeView {
        GLib.Tree<long, CaseTarget> cases;
        public CaseTreeIter iterator() {
            return { cases, null };
        }
    } // public struct GCaseTreeView

    /** cases 树集合的迭代器. 这玩意可比 Gee 的快多了. */
    public struct CaseTreeIter {
        unowned GLib.Tree<long, CaseTarget> cases;
        unowned TreeNode <long, CaseTarget>  node;

        public unowned CaseTarget? @get() { return node.value(); }
        public long case_n { get { return node.key(); } }

        public bool next() {
            if (node == null)
                node = cases.node_first();
            else
                node = node.next();
            return node != null;
        }
        public bool has_next() {
            return node != null && node.next() != null;
        }
        public bool has_prev() { return node != null && node.previous() != null; }
        public CaseTreeIter get_next() {
            return { cases, node == null? cases.node_first(): node.next() };
        }
        public CaseTreeIter get_prev() {
            return { cases, node == null? cases.node_first(): node.previous() };
        }
        public bool is_valid() { return this.cases != null; }
    } // public struct GTreeCaseIter
} // class Musys.IR.SwitchSSA