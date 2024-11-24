/**
 * === 列表集合常量 ===
 *
 * 在内存中线性布局的值，即包括结构体、数组、向量在内的集合常量.
 *
 * 列表集合常量都是懒加载的，也就是说, 空列表集合的列表内容字段一开始总是
 * null, 直到被读取或写入时才会创建一个实例.
 *
 * 和其他常量一样, 列表集合常量一旦构造完成就不可改变. 想修改某个列表集合
 * 常量的唯一办法就是删了重新创建一个.
 *
 * ==== 操作数表 ====
 *
 * 列表集合常量没有操作数表, 它的元素是另外存放在一个懒加载数组里的.
 *
 * ==== 文本表示 ====
 *
 * ``<start symbol> [<element>, ...] <end symbol>``
 */
public abstract class Musys.IR.ConstAggregate: ConstExpr {
    public AggregateType aggregate_type {
        get { return (AggregateType)this._value_type; }
    }
    public size_t nelems() {
        return aggregate_type.element_number;
    }

    internal Constant[]? _elems;
    /** 对外暴露的集合元素实例. 读写时没有检查, 不推荐使用. */
    public Constant[]? elems_nullable {
        get { return _elems; }
        internal owned set { _elems = (owned)value; }
    }
    /** 懒加载读写的集合元素. 读写时没有类型检查, 不推荐使用. */
    public Constant[] elems {
        get {
            if (_elems == null)
                _init0_elems();
            return _elems;
        }
        internal owned set {
            if (value != null)
                assert(value.length == aggregate_type.element_number);
            _elems = (owned)value;
        }
    }
    private void _init0_elems()
    {
        try {
            _elems = new Constant[aggregate_type.element_number];
            assert_nonnull(_elems);
            if (aggregate_type.tid == ARRAY_TYPE) {
                unowned Type elemty = static_cast<ArrayType>(value_type).element_type;
                var elem = Constant.CreateZero(elemty);
                for (int i = 0; i < _elems.length; i++)
                    _elems[i] = elem;
            } else {
                for (int i = 0; i < _elems.length; i++)
                    _elems[i] = Constant.CreateZero(aggregate_type.get_elem(i));
            }
        } catch (TypeMismatchErr e) {
            crash_err(e, "");
        }
    }

    /** 集合元素读访问函数, 会检查下标越界. */
    public Constant get_elem(int index) throws RuntimeErr {
        if (index < 0 || index >= (int)nelems())
            throw new RuntimeErr.INDEX_OVERFLOW("Requires [0, %lu) but got %d", nelems(), index);
        return this.elems[index];
    }
    /** 集合元素写访问函数, 会检查类型和下标越界. */
    public void set_elem(int index, Constant value) throws TypeMismatchErr, RuntimeErr
    {
        if (index < 0 || index >= (int)nelems())
            throw new RuntimeErr.INDEX_OVERFLOW("Requires [0, %lu) but got %d", nelems(), index);
        unowned var elems = this.elems;
        if (elems[index] == value)
            return;
        Type idx_ty = aggregate_type.get_elem(index);
        if (idx_ty.equals(value.value_type)) {
            elems[index] = value;
            return;
        }
        throw new TypeMismatchErr.MISMATCH(
            "Aggregate(%p).set[%d] requires %s but got %s",
            this, index, idx_ty.to_string(),
            value.value_type.to_string()
        );
    }

    public override bool is_zero {
        get {
            if (_elems == null)
                return true;
            foreach (Constant? c in _elems) {
                if (c != null && !c.is_zero)
                    return false;
            }
            return true;
        }
    }

    /** 拷贝一个不可变集合. */
    public ConstAggregate clone() { return _clone_impl(); }

    protected abstract ConstAggregate _clone_impl();

    protected ConstAggregate.C1_empty(Value.TID tid, AggregateType arrty) {
        base.C1(tid, arrty);
    }

    class construct {
        _istype[TID.CONST_AGGREGATE] = true;
        _shares_ref   = true;
        _is_aggregate = true;
    }
} // class Musys.IR.ConstAggregate
