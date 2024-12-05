public class Musys.IRUtil.Writer: IR.IValueVisitor {
    protected Runtime*  _rt;
    public    IR.Module module;
    public bool llvm_compatible { get; set; default = false; }

    public void write_stream(IOutputStream stream)
    {
        var rt = Runtime() {
            outs         = stream,
            indent_level = 0,
            space        = "    "
        };
        _rt = &rt;
        visit_module();
        _rt = null;
    }
    public void write_file(GLib.FileStream file = stdout) {
        write_stream(new FileOutStream(file));
    }
    public string write_string() {
        var strout = new StringOutStream();
        write_stream(strout);
        return strout.str_builder.free_and_steal();
    }
    public unowned string strtype(Musys.Type? type) {
        return type == null? "<null type>": type.to_string();
    }
    public unowned string strvty(Musys.IR.Value? value) {
        if (value == null)
            return "<null value>";
        Type? type = value.value_type;
        if (type == null)
            return "<null type>";
        return type.to_string();
    }
    public unowned IOutputStream? iouts() {
        return _rt == null? null: _rt->outs;
    }

    private void visit_module() {
        module.type_ctx._symbolled_structs.foreach((s, t) => {
            _rt->outs.printf("$%s = type %s", s, t.fields_to_string());
        });
        foreach (var def in module.global_def)
            def.value.accept(this);
        iouts().printf("\n;module %s\n", module.name);
    }
    public override void visit_const_data_zero(IR.ConstDataZero value) {
        iouts().putchar('0');
    }
    public override void visit_ptr_null(IR.ConstPtrNull value) {
        iouts().puts("null");
    }
    public override void visit_const_int(IR.ConstInt value) {
        iouts().printf("%ld", (long)value.i64_value);
    }
    public override void visit_const_float(IR.ConstFloat value) {
        string f64_str = "%.32lg".printf(value.f64_value);
        if (!f64_str.contains("."))
            f64_str += ".0";
        iouts().puts(f64_str);
    }
    public override void visit_undefined(IR.UndefinedValue udef) {
        iouts().puts(udef.is_poisonous ? "(poison)": "(undefined)");
    }
    public override void visit_const_array(IR.ConstArray value)
    {
        if (value.is_zero) {
            iouts().puts("[]");
            return;
        }
        iouts().puts("[ ");
        uint cnt = 0;
        foreach (var elem in value.elems) {
            unowned string elemty = strvty(elem);
            iouts().puts(cnt == 0? @"$(elemty) " :@", $(elemty) ");
            cnt++;
            _write_by_ref(elem);
        }
        iouts().puts(" ]");
    }
    public override void visit_const_struct(IR.ConstStruct value)
    {
        if (value.is_zero) {
            iouts().puts("{}");
            return;
        }
        iouts().puts("{ ");
        uint cnt = 0;
        foreach (var elem in (!)value.elems_nullable) {
            unowned string elemty = strvty(elem);
            iouts().puts(cnt == 0? @"$(elemty) " :@", $(elemty) ");
            cnt++;
            _write_by_ref(elem);
        }
        iouts().puts(" }");
    }
    public override void visit_const_index_ptr(IR.ConstIndexPtrExpr expr)
    {
        iouts().puts(@"getelementptr ($(expr.get_primary_type()), ptr ");
        _write_by_ref(expr.source);
        _write_const_index_body(expr.indices);
        iouts().putchar(')');
    }
    public override void visit_const_offset_of(IR.ConstOffsetOfExpr expr) {
        if (this.llvm_compatible)
            _write_offsetof_llvm(expr);
        else
            _write_offsetof_musys(expr);
    }
    private void _write_offsetof_musys(IR.ConstOffsetOfExpr expr) {
        iouts().puts(@"offsetof ($(expr.get_primary_type())");
        _write_const_index_body(expr.indices);
        iouts().putchar(')');
    }
    private void _write_offsetof_llvm(IR.ConstOffsetOfExpr expr) {
        iouts().puts(@"ptrtoint (ptr getelementptr ($(expr.get_primary_type()), ptr null");
        _write_const_index_body(expr.indices);
        iouts().printf(") to i%d)", module.target.ptr_size_bytes * 8);
    }
    private void _write_const_index_body(IR.ConstIndexPtrBase.IndexUse[] indices) {
        foreach (var uidx in indices) {
            unowned IR.Value idx = uidx.get();
            iouts().printf(", %s ", idx.value_type.to_string());
            _write_by_ref(idx);
        }
    }

    public override void visit_function(IR.Function func)
    {
        unowned string define = func.is_extern   ? "declare":  "define";
        unowned string visibl = func.is_internal ? "internal": "dso_local"; 
        iouts().puts(@"$define $visibl $(func.return_type) @$(func.name) (");

        unowned var args = func.args;
        for (uint i = 0; i < args.length; i++) {
            if (i != 0)
                iouts().puts(", ");
            unowned var arg = args[i];
            iouts().puts(@"$(arg.value_type) %$(arg.id)");
        }
        if (func.is_extern) {
            iouts().puts(")");
            _wrap_indent();
            return;
        }

        iouts().puts(") {");
        var entry = func.body._entry;
        _wrap_indent();
        this.visit_basicblock(entry);
        foreach (IR.BasicBlock b in func.body) {
            if (b == entry)
                continue;
            _wrap_indent();
            this.visit_basicblock(b);
        }
        iouts().puts("\n}");
        _wrap_indent();
    }
    public override void visit_global_variable(IR.GlobalVariable gvar)
    {
        unowned string visibl = gvar.visibility.get_display_name();
        unowned string mutabl = gvar.is_mutable? "global": "constant";
        iouts().puts(@"@$(gvar.name) = $visibl $mutabl $(gvar.content_type)");
        if (gvar.init_content != null) {
            iouts().putchar(' ');
            _write_by_ref(gvar.init_content);
        }
        iouts().printf(", align %lu\n", gvar.align);
    }
    public override void visit_global_alias(IR.GlobalAlias galias)
    {
        unowned string visibl = galias.visibility.get_display_name();
        var content_type = galias.content_type;
        iouts().puts(@"@$(galias.name) = $visibl alias $content_type, ptr @$(galias.direct_aliasee.name)");
    }
    public override void visit_basicblock(IR.BasicBlock block)
    {
        iouts().printf("%d:", block.id);
        _rt->indent_level++;
        foreach (var inst in block.instructions) {
            _wrap_indent();
            inst.accept(this);
#if MUSYS_DEBUG_PRINT_INST_INFO
            unowned string inst_klass = inst.get_class().get_name();
            iouts().puts(@" ;opcode $(inst.opcode) class $inst_klass");
#endif
        }
        _rt->indent_level--;
    }
    public override void visit_inst_binary(IR.BinarySSA inst)
    {
        unowned var type = inst.value_type;
        var opcode = inst.opcode;
        unowned string opcode_name = opcode.get_name();
        unowned string sign = "";
        int id   = inst.id;

        if (!opcode.is_float_op() && !opcode.is_logic_op() &&
            !opcode.is_shift_op() && !opcode.is_divrem_op())
            sign = inst.is_signed? " nsw": " nuw";

        iouts().puts(@"%$id = $opcode_name$sign $type ");
        _write_by_ref(inst.lhs);
        if (opcode.is_shift_op())
            iouts().puts(@", $(inst.rhs.value_type)");
        else
            iouts().puts(", ");
        _write_by_ref(inst.rhs);
    }
    public override void visit_inst_compare(IR.CompareSSA inst)
    {
        unowned string operandty = inst.operand_type.to_string();
        unowned string opcode = inst.opcode == ICMP ? "icmp": "fcmp";
        unowned var condition = inst.condition;
        iouts().puts(@"%$(inst.id) = $opcode $condition $operandty ");
        _write_by_ref(inst.lhs);
        iouts().puts(", ");
        _write_by_ref(inst.rhs);
    }
    public override void visit_inst_unary(IR.UnaryOpSSA inst)
    {
        unowned var type = inst.value_type;
        var opcode = inst.opcode;
        if (llvm_compatible) {
            _write_unaryop_llvm(inst, opcode, type);
        } else {
            unowned string opcode_name = opcode.get_name();
            iouts().puts(@"%$(inst.id) = $opcode_name $type ");
            _write_by_ref(inst.operand);
        }
    }
    private void _write_unaryop_llvm(IR.UnaryOpSSA inst, IR.OpCode opcode, Musys.Type type) {
        unowned string inst_head = null;
        switch (inst.opcode) {
            case INEG:  inst_head = "%%%d = sub nsw %s 0, "; break;
            case FNEG:  inst_head = "%%%d = fsub %s 0.0, ";  break;
            case NOT:   inst_head = "%%%d = xor %s -1, ";    break;
            default: crash_fmt("opcode %s is not legal for unary operation", inst.opcode.to_string());
        }
        iouts().printf(inst_head, inst.id, type.to_string());
        _write_by_ref(inst.operand);
    }
    public override void visit_inst_cast(IR.CastSSA inst)
    {
        unowned var srcty = inst.source_type;
        unowned var dstty = inst.value_type;
        var opcode = inst.opcode;
        unowned string opcode_name = opcode.get_name();
        iouts().puts(@"%$(inst.id) = $opcode_name $srcty ");
        _write_by_ref(inst.source);
        iouts().puts(@" to $dstty");
    }
    public override void visit_inst_call(IR.CallSSA inst)
    {
        unowned var outs = iouts();
        unowned var calleety = inst.callee_fn_type;
        unowned var retty = calleety.return_type;
        iouts().puts((retty is VoidType) ? "call void ": @"%$(inst.id) = call $retty ");
        iouts().printf("@%s (", inst.fn_callee.name);
        uint cnt = 0;
        foreach (var arg in inst.uargs) {
            if (cnt != 0)
                iouts().puts(", ");
            cnt++;
            unowned var varg = arg.arg;
            iouts().printf("%s ", varg.value_type.to_string());
            _write_by_ref(varg);
        }
        outs.putchar(')');
    }
    public override void visit_inst_dyn_call(IR.DynCallSSA inst)
    {
        unowned var outs = iouts();
        unowned var calleety = inst.callee_fn_type;
        unowned var retty = calleety.return_type;
        if (llvm_compatible)
            iouts().puts(retty.is_void ? "call void ":    @"%$(inst.id) = call $retty ");
        else
            iouts().puts(retty.is_void ? "dyncall void ": @"%$(inst.id) = dyncall $retty ");

        _write_by_ref(inst.callee);
        iouts().puts(" (");
        uint cnt = 0;
        foreach (var arg in inst.uargs) {
            if (cnt != 0)
                iouts().puts(", ");
            cnt++;
            unowned var varg = arg.arg;
            iouts().printf("%s ", varg.value_type.to_string());
            _write_by_ref(varg);
        }
        outs.putchar(')');
    }
    public override void visit_inst_alloca(IR.AllocaSSA inst)
    {
        var id = inst.id;
        var ty = inst.target_type;
        var align = inst.align;
        iouts().puts(@"%$id = alloca $ty, align $align");
    }
    public override void visit_inst_dyn_alloca(IR.DynAllocaSSA inst)
    {
        var id = inst.id;
        var ty = inst.target_type;
        var align = inst.align;
        var length = inst.length;
        iouts().puts(
            llvm_compatible?
                @"%$id = alloca $ty, $(length.value_type) ":
                @"%$id = dynalloca $ty, $(length.value_type) "
        );
        _write_by_ref(length);
        iouts().printf(" align %lu", align);
    }
    public override void visit_inst_load(IR.LoadSSA inst)
    {
        var id = inst.id;
        var ty = inst.value_type;
        var align = inst.align;
        var operand = inst.operand;
        var operandty = inst.source_type;
        iouts().puts(@"%$id = load $ty, $operandty ");
        _write_by_ref(operand);
        iouts().printf(", align %lu", align);
    }
    public override void visit_inst_store(IR.StoreSSA inst)
    {
        var align = inst.align;
        var srcty = inst.source_type;
        var dstty = inst.target_type;
        var src = inst.source;
        var dst = inst.target;
        iouts().puts(@"store $srcty ");
        _write_by_ref(src);
        iouts().puts(@", $dstty ");
        _write_by_ref(dst);
        iouts().printf(", align %lu", align);
    }
    public override void visit_inst_return(IR.ReturnSSA inst)
    {
        var ty = inst.value_type;
        IR.Value retval = inst.retval;
        if (ty.is_void) {
            iouts().puts("ret void");
        } else {
            iouts().puts(@"ret $ty ");
            _write_by_ref(retval);
        }
    }
    public override void visit_inst_unreachable(IR.UnreachableSSA inst) {
        iouts().puts("unreachable");
    }
    public override void visit_inst_jump(IR.JumpSSA inst) {
        iouts().printf("br label %%%d", inst.target.id);
    }
    public override void visit_inst_branch(IR.BranchSSA inst)
    {
        IR.Value cond = inst.condition;
        iouts().puts(@"br $(cond.value_type) ");
        _write_by_ref(cond);
        iouts().printf(", label %%%d, label %%%d",
                    inst.if_true.id, inst.if_false.id);
    }
    public override void visit_inst_switch(IR.SwitchSSA inst)
    {
        IR.Value cond = inst.condition;
        iouts().puts(@"switch $(cond.value_type) ");
        _write_by_ref(cond);
        iouts().printf(", label %%%d [", inst.default_target.id);
        _rt->indent_level++;
        foreach (var ct in inst.view_cases()) {
            _wrap_indent();
            iouts().printf("%s %ld, label %%%d", cond.value_type.to_string(), ct.case_n, ct.target.id);
        }
        _rt->indent_level--;
        _wrap_indent();
        iouts().putchar(']');
    }
    public override void visit_inst_phi(IR.PhiSSA inst)
    {
        unowned var type = inst.value_type;
        int id = inst.id;
        iouts().puts(@"%$id = phi $type ");
        uint cnt = 0;
        foreach (var entry in inst.from_map) {
            IR.Value   operand = entry.value.get_operand();
            IR.BasicBlock from = entry.key;
            iouts().puts(cnt != 0? ", [ ": "[ ");
            cnt++;
            _write_by_ref(operand);
            iouts().printf(",  %%%d ]", from.id);
        }
    }
    public override void visit_inst_index_ptr(IR.IndexPtrSSA inst)
    {
        var id = inst.id;
        var ity = inst.primary_target_type;
        var pty = inst.source.value_type;
        iouts().puts(@"%$id = getelementptr inbounds $ity, $pty ");
        _write_by_ref(inst.source);
        foreach (var idx in inst.indices) {
            iouts().puts(@", $(idx.index.value_type) ");
            _write_by_ref(idx.index);
        }
    }
    public override void visit_inst_select(IR.BinarySelectSSA inst)
    {
        iouts().puts(@"%$(inst.id) = select i1 ");
        _write_by_ref(inst.condition);
        iouts().printf(", %s ", inst.value_type.to_string());
        _write_by_ref(inst.if_true);
        iouts().puts(", ");
        _write_by_ref(inst.if_false);
    }
    public override void visit_inst_index_extract(IR.IndexExtractSSA inst)
    {
        var id = inst.id;
        var srcty = inst.aggregate_type;
        var dstty = inst.index.value_type;
        iouts().puts(@"%$id = extractelement $srcty ");
        _write_by_ref(inst.aggregate);
        iouts().puts(@", $dstty ");
        _write_by_ref(inst.index);
    }
    public override void visit_inst_index_insert(IR.IndexInsertSSA inst)
    {
        var id = inst.id;
        var srcty = inst.aggregate_type;
        var dstty = inst.index.value_type;
        var elmty = inst.element_type;
        iouts().puts(@"%$id = insertelement $elmty ");
        _write_by_ref(inst.element);
        iouts().puts(@", $srcty ");
        _write_by_ref(inst.aggregate);
        iouts().puts(@", $dstty ");
        _write_by_ref(inst.index);
    }

    private void _write_by_ref(IR.Value value)
    {
        if (value.shares_ref)
            value.accept(this);
        else if (value.isvalue_by_id(GLOBAL_OBJECT))
            iouts().printf("@%s", static_cast<IR.GlobalObject>(value).name);
        else
            iouts().printf("%%%d", value.id);
    }
    private void _wrap_indent()
    {
        uint indent_level = _rt->indent_level;
        unowned string space = _rt->space;
        unowned var outs = iouts();
        outs.putchar('\n');
        for (uint i = 0; i < indent_level; i++)
            iouts().puts(space);
    }

    public Writer(IR.Module module) {
        this.module = module;
    }

    protected struct Runtime {
        IOutputStream   outs;
        uint    indent_level;
        string  space;
    }
} // public class Musys.IRUtil.Writer
