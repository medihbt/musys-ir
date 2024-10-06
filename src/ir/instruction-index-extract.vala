public class Musys.IR.IndexExtractSSA: IndexSSABase {
    public override void accept(IValueVisitor visitor) {
        visitor.visit_inst_index_extract(this);
    }

    public IndexExtractSSA.raw(AggregateType src_type) {
        base.C1(INDEX_EXTRACT_SSA, INDEX_EXTRACT,
                src_type, src_type.get_element_type_at(0));
    }
    public IndexExtractSSA.from(Value aggregate, Value index)
    {
        Type type = aggregate.value_type;
        if (!type.is_array)
            crash(@"IndexExtractSSA::from()::array requires array type, but got $type");
        var atype = static_cast<AggregateType>(type);
        this.raw(atype);
        this.aggregate = aggregate;
        this.index = index;
    }
    class construct { _istype[TID.INDEX_EXTRACT_SSA] = true; }
}
