public errordomain Musys.IR.PhiError {
    NO_INCOMING_BLOCK;
}

/**
 * === PHI 结点 ===
 *
 * SSA 数据流的必备结点, 汇总不同入口基本块的数据流. PHI 结点是一张
 * 基本块-操作数映射表 (B, V), 其含义是倘若控制流从某个入口基本块 B
 * 进入该基本块, 那 PHI 结点的值就代表操作数 V 的值. 暴露这个映射
 * 关系的对象都是 `PhiSSA.FromUse` 类 (IR.Use 子类) 的.
 *
 * PHI 结点永远处在基本块的最前面. 倘若一个基本块里有不止一个 PHI 结点,
 * 那除非这个基本块的入口之一是自己, 否则这些结点不能互为操作数.
 *
 * ==== 指令基本信息 ====
 *
 * ''类型'': 操作数的类型就是指令的类型
 *
 * ''操作数表'':
 * - `[0:] = {b, v}.v`: {from_bb, value} 基本块-操作数映射的操作数
 *
 * ''文本格式'': `%<id> = phi <type> [value, from_bb], ...`
 */
public class Musys.IR.PhiSSA: Instruction {
    public Gee.HashMap<unowned BasicBlock, FromUse> from_map{get;}

    public bool has_from(BasicBlock from) {
        return from_map.has_key(from);
    }
    public FromUse get_use(BasicBlock from) throws PhiError {
        if (!from_map.has_key(from))
            throw new PhiError.NO_INCOMING_BLOCK("phi %p, index %p".printf(this, from));
        return from_map[from];
    }
    public FromUse set_from(BasicBlock from, Value value)
    {
        FromUse use = null;
        if (from_map.has_key(from)) {
            use = from_map[from];
        } else {
            use = new FromUse();
            use.attach_back(this);
            _from_map[from] = use;
            use.from       = from;
        }
        use.set_operand(value);
        return use;
    }
    public void remove_from(BasicBlock from)
    {
        if (!has_from(from))
            return;
        FromUse use = from_map[from];
        use.do_remove_operand();
    }
    public new Value get(BasicBlock from)
    {
        try {
            var u = get_use(from);
            return u._operand;
        } catch (PhiError e) {
            crash_err(e);
        }
    }
    public new void set(BasicBlock from, Value value) {
        set_from(from, value);
    }

    public unowned BasicBlock? get_income_bb(Use u)
    requires (u.user == this) {
        return (u is FromUse)? ((FromUse)u).from: null;
    }
    private void _clean_from() {
        _from_map.clear();
        operands.clean();
    }

    public override void on_parent_finalize() {
        _clean_from();
        base._deep_clean();
    }
    public override void on_function_finalize() {
        _clean_from();
        base._fast_clean();
    }
    public override void accept(IValueVisitor visitor) {
        visitor.visit_inst_phi(this);
    }

    public PhiSSA.raw(Type type) {
        base.C1(PHI_SSA, PHI, type);
        this._from_map = new Gee.HashMap<unowned BasicBlock, FromUse>();
    }
    class construct { _istype[TID.PHI_SSA] = true; }

    /**
     * === PhiSSA 操作数映射关系 ===
     *
     * 表示 PHI 结点中''基本块-操作数映射关系''的使用关系.
     */
    public class FromUse: Use {
        public unowned PhiSSA parent {
            get { return static_cast<PhiSSA>(_user); }
        }
        public unowned BasicBlock from;
        internal       Value  _operand;
        public inline  Type value_type { get { return parent.value_type; } }

        public inline unowned Value? get_operand() { return _operand; }
        public inline void set_operand(Value value) {
            if (_operand == value)
                return;
            type_match_or_crash(value_type, value.value_type);
            User.replace_use(_operand, value, this);
            _operand = value;
        }
        internal inline Use do_remove_operand()
        {
            if (_operand != null)
                _operand.remove_use_as_usee(this);
            FromUse othis = this;
            parent.from_map.unset(from, out othis);
            remove_this();
            return othis;
        }
        public override Value? usee {
            get { return _operand; }
            set {
                if (value == null) do_remove_operand();
                set_operand(value);
            }
        }
        public override Use remove_operand() {
            return do_remove_operand();
        }
    }
}
