namespace Musys.IR {
    /**
     * 基本块终止子. 只有实现该接口的指令类才能放在基本块末尾.
     * @see BasicBlock
     */
    public interface IBasicBlockTerminator: Instruction {
        /**
         * ==== 跳转目标集合 ====
         *
         * 该属性存储所有的跳转目标. 注意, 集合的迭代器可能会随着对应跳转目标的卸载而失效.
         *
         * WARNING: ''和 use-def 关系一样, 不要随意增删集合内的结点''. 否则可能会造成
         * 内部数据不一致错误.
         */
        public JumpTargetList jump_targets { get { return get_jump_target_impl(); } }
        protected abstract unowned JumpTargetList get_jump_target_impl();

        /** 跳转目标是否存在 */
        public abstract bool has_jump_target();

        /** 判断自己会不会终止函数 */
        public virtual bool terminates_function() { return true; }

        /** 跳转目标数量. 与遍历 API 兼容. */
        public size_t ntargets { get { return jump_targets.length; } }

        /** 遍历读取跳转目标. 与遍历版 API 兼容. */
        public ForeachResult foreach_target(BasicBlock.ReadFunc fn)
        {
            foreach (JumpTarget target in jump_targets) {
                if (fn(target.target))
                    return STOP;
            }
            return CONTINUE;
        }
        /** 遍历修改跳转目标. 与遍历版 API 兼容. */
        public ForeachResult replace_target(BasicBlock.ReplaceFunc fn)
        {
            foreach (JumpTarget target in jump_targets) {
                BasicBlock? newt = fn(target.target);
                if (newt == null)
                    return STOP;
                else if (newt != target.target)
                    target.target = newt;
            }
            return CONTINUE;
        }
        /** 默认跳转目标, 最先被遍历到的那个. 与遍历版 API 兼容. */
        public BasicBlock? default_target {
            get {
                var jmp_targets = jump_targets;
                var it = jmp_targets.iterator();
                if (it.next() == false)
                    return null;
                return it.get().target;
            }
        }
    } // public interface IBasicBlockTerminator

    /**
     * === 跳转目标代理类 ===
     *
     * 在控制流图(CFG)中表示一个从某个终止指令 (如条件跳转、switch 语句等)
     * 指向其基本块目标的边。它用于维护控制流图中的跳转关系, 在跳转关系发生变更时
     * 会自动修改跳转目标的入边集合。
     */
    public class JumpTarget {
        internal         JumpTarget?     _next;
        internal unowned JumpTarget?     _prev;
        internal unowned JumpTargetList? _list;
        internal unowned BasicBlock    _target;
        internal long    _order;

        /** 跳转目标的类型，如默认跳转、条件为真跳转、开关语句跳转等。 */
        public Kind kind  { get; internal set; }

        /** 跳转目标的序号。一般为 0, 在 switch 指令中表示属于哪个 case. */
        public long order { get { return _order; } protected set { _order = value; } }

        /** 产生此跳转目标的终止指令。 */
        public unowned IBasicBlockTerminator terminator { get; internal set; }

        /** 产生此跳转目标的源基本块 */
        public unowned BasicBlock? get_from_bb() {
            IBasicBlockTerminator? terminator = this.terminator;
            return terminator == null? null: terminator.parent;
        }

        public bool edge_equals(JumpTarget rhs)
        {
            if (this == rhs)
                return true;
            return this.terminator == rhs.terminator &&
                   this.target     == rhs.target;
        }

        /**
         * ==== 目标基本块 ====
         *
         * 修改时，如果新的目标与当前目标不同，将更新跳转关系：从当前目标基本块的
         * 入边集合中移除此边，然后将此控制流图边添加到新目标基本块的入边列表中。
         */
        public unowned BasicBlock target {
            get { return _target; }
            set {
                if (_target == value)
                    return;
                _manage_incomes(_target, value);
                _target = value;
            }
        }
        private void _manage_incomes(BasicBlock? prev, BasicBlock? value) {
            if (prev != null && prev.incomes != null)
                prev.incomes.remove(this);
            if (value != null && value.incomes != null)
                value.incomes.insert(this, this);
        }
        /** 跳转目标启用入边集合时的槽函数: 把自己加入到新入边集合中. */
        public void on_income_enable() {
            if (_target != null && _target.incomes != null)
                _target.incomes.insert(this, this);
        }

        public bool is_attached() { return _list != null; }

        public unowned JumpTarget attach_back(JumpTargetList list)
        {
            if (this.is_attached())
                crash_fmt("attach_back() function rejects attached blocks %p", this);
            this.terminator = list.terminator;
            this._list      = list;
            JumpTarget end  = list.end().get();
            JumpTarget prev = end._prev;
            this._next = end;  this._prev  = prev;
            end._prev  = this; _prev._next = this;
            list.length += 1;
            return this;
        }
        public unowned JumpTarget attach_after_node(JumpTarget prev)
        {
            if (this.is_attached())
                crash_fmt("attach_back() function rejects attached blocks %p", this);
            this.terminator = prev.terminator;
            this._list = prev._list;
            JumpTarget next = prev._next;
            assert_nonnull(next);
            this._next = next; this._prev = prev;
            next._prev = this; prev._next = this;
            _list.length += 1;
            return this;
        }
        public JumpTarget unplug() requires (this.is_attached())
        {
            JumpTarget othis = this;
            JumpTarget next = othis._next, prev = othis._prev;
            next._prev = prev; prev._next = next;
            this._prev = null; this._next = null;
            this._list = null;
            _list.length -= 1;
            return othis;
        }

        public JumpTarget(Kind kind) { this.kind = kind; }

        /** 如果此跳转目标指向一个基本块，则从该基本块的入口列表中移除此跳转目标。 */
        ~JumpTarget() {
            if (_target != null && _target.incomes != null)
                _target.incomes.remove(this);
        }

        /**
         * === 跳转目标的类型枚举 ===
         * 
         * 包括默认跳转、条件为真跳转、switch 跳转、函数调用异常跳转等类型，
         * 以及用于内部处理的特殊类型(''\_GUIDE_BEGIN\_'', ''\_GUIDE_END\_'')。
         */
        public enum Kind {
            _GUIDE_BEGIN_, _GUIDE_END_,
            DEFAULT, IF_TRUE, SWITCH_CASE,
            INVOKE_EXCEPTION;
            public static Kind IF_FALSE()      { return DEFAULT; }
            public static Kind INVOKE_NORMAL() { return DEFAULT; }

            /** 该跳转目标是不是头尾结点. */
            public bool is_guide() {
                return this == _GUIDE_BEGIN_ || this == _GUIDE_END_;
            }
        }
        public delegate ForeachResult ReadFunc(JumpTarget target);
    } // public class JumpTargetEdge

    public class JumpTargetList {
        public unowned IBasicBlockTerminator terminator { get; internal set; }
        private JumpTarget _node_begin;
        private JumpTarget _node_end;
        public  size_t length { get; internal set; }

        /** Vala 迭代器协议: 返回第一个元素之前的那个迭代器 */
        public Iterator iterator() { return { _node_begin }; }
        public Iterator end()      { return { _node_end }; }

        private void _init_node()
        {
            _node_begin = new JumpTarget(_GUIDE_BEGIN_) { terminator = this._terminator };
            _node_end   = new JumpTarget(_GUIDE_END_)   { terminator = this._terminator };
            _node_begin._next = _node_end;
            _node_end._prev = _node_begin;
            this._length = 0;
        }
        public JumpTargetList(IBasicBlockTerminator terminator) {
            this.terminator = terminator;
            this._init_node();
        }
#if MUSYS_DEBUG_REFCNT_COUNT
        ~JumpTargetList() {
            message("JumpTargetList(%p): %lu targets, refcount %u", this, length, ref_count);
            var beg = _node_begin;
            do {
                message("JumpTarget kind %s order %ld addr %p refcount %u",
                    beg.kind.to_string(), beg.order, beg, beg.ref_count);
                beg = beg._next;
            } while (beg != null);
        }
#endif

        public struct Iterator {
            unowned JumpTarget? curr;
            public bool next() requires (curr != null)
            {
                if (curr._next == null)
                    return false;
                curr = curr._next;
                return curr.kind != _GUIDE_END_;
            }
            public unowned JumpTarget get() requires (curr != null) { return curr; }

            public bool is_valid() {
                return curr != null;
            }
        }
    } // public class JumpTargetList
} // namespace Musys.IR