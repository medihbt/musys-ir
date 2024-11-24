/**
 * === 数组常量表达式 ===
 *
 * @see Musys.IR.ConstAggregate
 */
public sealed class Musys.IR.ConstArray: ConstAggregate {
    public ArrayType array_type {
        get { return static_cast<ArrayType>(this._value_type); }
    }

    /** 返回自己的拷贝，用于修改. 注意, 返回对象的元素还是不可变的. */
    public new ConstArray clone()
    {
        var ret = new ConstArray.empty(this.array_type);
        if (elems_nullable != null)
            ret.elems_nullable = elems_nullable;
        return ret;
    }
    protected override ConstAggregate _clone_impl() { return this.clone(); }
    public override void accept(IValueVisitor visitor) {
        visitor.visit_const_array(this);
    }

    public ConstArray.empty(ArrayType arrty) {
        base.C1_empty(CONST_ARRAY, arrty);
        this.opcode = CONST_ARRAY;
    }

    class construct {
        _istype[TID.CONST_ARRAY] = true;
    }
} // class Musys.IR.ConstArray