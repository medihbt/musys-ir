/**
 * === 结构体常量表达式 ===
 *
 * @see Musys.IR.ConstAggregate
 */
public sealed class Musys.IR.ConstStruct: ConstAggregate {
    public StructType struct_type {
        get { return static_cast<StructType>(value_type); }
    }

    /** 返回自己的拷贝，用于修改. 注意, 返回对象的元素还是不可变的. */
    public new ConstStruct clone()
    {
        var ret = new ConstStruct.empty(this.struct_type);
        if (elems_nullable != null)
            ret.elems_nullable = this.elems_nullable;
        return ret;
    }
    protected override ConstAggregate _clone_impl() { return this.clone(); }
    public override void accept(IValueVisitor visitor) {
        visitor.visit_const_struct(this);
    }

    public ConstStruct.empty(StructType sty) {
        base.C1_empty(CONST_STRUCT, sty);
        this.opcode = OpCode.CONST_STRUCT;
    }

    class construct {
        _istype[TID.CONST_STRUCT] = true;
    }
} // class Musys.IR.ConstStruct
