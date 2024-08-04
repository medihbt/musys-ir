public class Musys.IR.IndexExtractSSA: IndexSSABase {
    public override void accept(IValueVisitor visitor) {
        visitor.visit_inst_index_extract(this);
    }

    public IndexExtractSSA.raw(ArrayType src_type) {
        base.C1(INDEX_EXTRACT_SSA, INDEX_EXTRACT,
                src_type, src_type.element_type);
    }
    public IndexExtractSSA.from(Value array, Value index)
    {
        Type type = array.value_type;
        if (!type.is_array)
            crash(@"IndexExtractSSA::from()::array requires array type, but got $type");
        var atype = static_cast<ArrayType>(type);
        this.raw(atype);
        this.array   = array;
        this.index = index;
    }
    class construct { _istype[TID.INDEX_EXTRACT_SSA] = true; }
}
