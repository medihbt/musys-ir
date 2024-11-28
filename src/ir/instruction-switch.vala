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
 * ```
 * switch <int type> <condition>, label <default target>, [
 *     i64 <case 1>, label %<target 1>
 *     i64 <case 2>, label %<target 2>
 *     ...
 * ]
 * ```
 *
 * SwitchSSA 保证在遍历时条件总是从小到大排序的. 因此, 该实现内部采用有序树存储跳转条件.
 */
public class Musys.IR.SwitchSSA: JumpBase {
    public Gee.TreeMap<long, Case> cases {
        get; internal owned set;
        default = new Gee.TreeMap<long, Case>(longcmp);
    }

    public Case? get_case(long case_n) { return cases[case_n]; }
    public void  set_case(long case_n, BasicBlock? bb)
    {
        Case? c = cases[case_n];
        if (c == null) {
            if (bb != null)
                cases[case_n] = new Case.from(bb, case_n);
        } else if (bb != null) {
            c.bb = bb;
        } else {
            remove_case(case_n);
        }
    }
    public void remove_case(long case_n) {
        cases.unset(case_n);
    }

    public Case? find_case(BasicBlock target) {
        var? res = cases.first_match((entry) => entry.value.bb == target);
        return res == null? null: res.value;
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

    public override ForeachResult foreach_jump_target(BasicBlock.ReadFunc fn) {
        if (fn(_default_target))
            return STOP;
        return ForeachResult.FromGee(cases.foreach((entry) => !fn(entry.value.bb)));
    }

    /** {@link IBasicBlockTerminator.replace_target} */
    public override ForeachResult replace_jump_target(BasicBlock.ReplaceFunc fn) {
        BasicBlock? dres = fn(_default_target);
        if (dres == null)
            return STOP;
        else if (dres != _default_target)
            _default_target = dres;
        return ForeachResult.FromGee(
            cases.foreach((entry) => {
                BasicBlock  bb  = entry.value.bb;
                BasicBlock? res = fn(bb);
                if (res == null)
                    return false;
                else if (res != bb)
                    entry.value.bb = res;
                return true;
            }
        ));
    } // override bool replace_jump_target(fn: (BasicBlock) => BasicBlock?)

    public override int64 n_jump_targets() { return cases.size + 1; }
    public override void accept(IValueVisitor visitor) {
        visitor.visit_inst_switch(this);
    }
    public override void on_parent_finalize() {
        _default_target = null;
        cases = null;
        base._deep_clean();
    }
    public override void on_function_finalize() {
        _default_target = null;
        cases = null;
        this._deep_clean();
    }

    public SwitchSSA.raw(VoidType voidty) {
        base.C1(TID.SWITCH_SSA, OpCode.SWITCH, voidty);
        this._ucondition = new CondUse().attach_back(this);
    }
    public SwitchSSA.with_default(Value condition, BasicBlock default_target) {
        this.raw(default_target.value_type.type_ctx.void_type);
        this._default_target = default_target;
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
    public SwitchSSA.from(Value condition, BasicBlock default_target, Gee.Traversable<Case> cases) {
        this.with_default(condition, default_target);
        cases.foreach((c) => {
            if (c.bb != default_target)
                this.set_case(c.case_n, c.bb);
            return true;
        });
    }
    class construct { _istype[TID.SWITCH_SSA] = true; }

    /** Switch 的条件分支 */
    public class Case {
        public unowned BasicBlock bb;
        public long           case_n;

        public Case.from(BasicBlock bb, long case_n) {
            this.bb = bb;
            this.case_n = case_n;
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
} // class Musys.IR.SwitchSSA