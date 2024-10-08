public class Musys.IRUtil.Writer: IR.IValueVisitor {
    protected Runtime*  _rt;
    public    IR.Module module;

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

    private void visit_module() {
        foreach (var ste in module.type_ctx._symbolled_struct_types) {
            StructType sty = ste.value;
            _rt.outs.puts(@"$sty = type $(sty.fields_to_string())\n");
        }
        foreach (var def in module.global_def)
            def.value.accept(this);
        _rt.outs.printf("\n;module %s\n", module.name);
    }
    public override void visit_const_data_zero(IR.ConstDataZero value) {
        _rt->outs.putchar('0');
    }
    public override void visit_ptr_null(IR.ConstPtrNull value) {
        _rt->outs.puts("null");
    }
    public override void visit_const_int(IR.ConstInt value) {
        _rt->outs.printf("%ld", (long)value.i64_value);
    }
    public override void visit_const_float(IR.ConstFloat value) {
        _rt->outs.printf("%lf", value.f64_value);
    }
    public override void visit_undefined(IR.UndefinedValue udef) {
        unowned var outs = _rt->outs;
        outs.puts(udef.is_poisonous ? "(poison)": "(undefined)");
    }
    public override void visit_array_expr(IR.ArrayExpr value)
    {
        unowned var outs = _rt->outs;
        if (value.is_zero) {
            outs.puts("[]");
            return;
        }
        outs.puts("[ ");
        uint cnt = 0;
        foreach (var elem in value.elems) {
            outs.puts(cnt == 0? @"$(elem.value_type) " :@", $(elem.value_type) ");
            cnt++;
            _write_by_ref(elem);
        }
        outs.puts(" ]");
    }
    public override void visit_struct_expr(IR.StructExpr value)
    {
        unowned var outs = _rt->outs;
        if (value.is_zero) {
            outs.puts("{}");
            return;
        }
        outs.puts("{ ");
        uint cnt = 0;
        foreach (var elem in (!)value.nullable_elems) {
            outs.puts(cnt == 0? @"$(elem.value_type) " :@", $(elem.value_type) ");
            cnt++;
            _write_by_ref(elem);
        }
        outs.puts(" }");
    }

    public override void visit_function(IR.Function func)
    {
        unowned var    outs = _rt->outs;
        unowned string define = func.is_extern   ? "declare":  "define";
        unowned string visibl = func.is_internal ? "internal": "dso_local"; 
        outs.puts(@"$define $visibl $(func.return_type) @$(func.name) (");

        unowned var args = func.args;
        for (uint i = 0; i < args.length; i++) {
            if (i != 0)
                outs.puts(", ");
            unowned var arg = args[i];
            outs.puts(@"$(arg.value_type) %$(arg.id)");
        }
        if (func.is_extern) {
            outs.puts(")");
            _wrap_indent();
            return;
        }

        outs.puts(") {");
        var entry = func.body.entry;
        _wrap_indent();
        this.visit_basicblock(entry);
        foreach (IR.BasicBlock b in func.body) {
            if (b == entry)
                continue;
            _wrap_indent();
            this.visit_basicblock(b);
        }
        outs.puts("\n}");
        _wrap_indent();
    }
    public override void visit_global_variable(IR.GlobalVariable gvar)
    {
        unowned var    outs = _rt->outs;
        unowned string visibl = gvar.visibility.get_display_name();
        unowned string mutabl = gvar.is_mutable? "global": "constant";
        outs.puts(@"@$(gvar.name) = $visibl $mutabl $(gvar.content_type)");
        if (gvar.init_content != null) {
            outs.putchar(' ');
            _write_by_ref(gvar.init_content);
        }
        outs.printf(", align %lu\n", gvar.align);
    }
    public override void visit_global_alias(IR.GlobalAlias galias)
    {
        unowned var    outs = _rt->outs;
        unowned string visibl = galias.visibility.get_display_name();
        var content_type = galias.content_type;
        outs.puts(@"@$(galias.name) = $visibl alias $content_type, ptr @$(galias.direct_aliasee.name)");
    }
    public override void visit_basicblock(IR.BasicBlock block)
    {
        unowned var outs = _rt->outs;
        outs.printf("%d:", block.id);
        _rt->indent_level++;
        foreach (var inst in block.instructions) {
            _wrap_indent();
            var opcode = inst.opcode;
            unowned var inst_klass = inst.get_class().get_name();
            inst.accept(this);
            outs.puts(@" ;opcode $opcode class $inst_klass");
        }
        _rt->indent_level--;
    }
    public override void visit_inst_binary(IR.BinarySSA inst)
    {
        unowned var outs = _rt->outs;
        unowned var type = inst.value_type;
        var opcode = inst.opcode;
        unowned string opcode_name = opcode.get_name();
        unowned string sign = "";
        int id   = inst.id;

        if (!opcode.is_float_op() && !opcode.is_logic_op() &&
            !opcode.is_shift_op() &&
            opcode != SDIV && opcode != UDIV)
            sign = inst.is_signed? " nsw": " nuw";

        outs.puts(@"%$id = $opcode_name$sign $type ");
        _write_by_ref(inst.lhs);
        if (opcode.is_shift_op())
            outs.puts(@", $(inst.rhs.value_type)");
        else
            outs.puts(", ");
        _write_by_ref(inst.rhs);
    }
    public override void visit_inst_compare(IR.CompareSSA inst)
    {
        unowned var  outs = _rt->outs;
        unowned string operandty = inst.operand_type.to_string();
        unowned string opcode = inst.opcode == ICMP ? "icmp": "fcmp";
        unowned var condition = inst.condition;
        outs.puts(@"%$(inst.id) = $opcode $condition $operandty ");
        _write_by_ref(inst.lhs);
        outs.puts(", ");
        _write_by_ref(inst.rhs);
    }
    public override void visit_inst_unary(IR.UnaryOpSSA inst)
    {
        unowned var outs = _rt->outs;
        unowned var type = inst.value_type;
        var opcode = inst.opcode;
        unowned string opcode_name = opcode.get_name();
        outs.puts(@"%$(inst.id) = $opcode_name $type ");
        _write_by_ref(inst.operand);
    }
    public override void visit_inst_cast(IR.CastSSA inst)
    {
        unowned var outs = _rt->outs;
        unowned var srcty = inst.source_type;
        unowned var dstty = inst.value_type;
        var opcode = inst.opcode;
        unowned string opcode_name = opcode.get_name();
        outs.puts(@"%$(inst.id) = $opcode_name $srcty ");
        _write_by_ref(inst.source);
        outs.puts(@" to $dstty");
    }
    public override void visit_inst_call(IR.CallSSA inst)
    {
        unowned var outs = _rt->outs;
        unowned var calleety = inst.callee_fn_type;
        unowned var retty = calleety.return_type;
        outs.puts((retty is VoidType) ? "call void ": @"%$(inst.id) = call $retty ");
        outs.printf("@%s (", inst.fn_callee.name);
        uint cnt = 0;
        foreach (var arg in inst.uargs) {
            if (cnt != 0)
                outs.puts(", ");
            cnt++;
            unowned var varg = arg.arg;
            outs.printf("%s ", varg.value_type.to_string());
            _write_by_ref(varg);
        }
        outs.putchar(')');
    }
    public override void visit_inst_alloca(IR.AllocaSSA inst)
    {
        unowned var outs = _rt->outs;
        var id = inst.id;
        var ty = inst.target_type;
        var align = inst.align;
        outs.puts(@"%$id = alloca $ty, align $align");
    }
    public override void visit_inst_dyn_alloca(IR.DynAllocaSSA inst)
    {
        unowned var outs = _rt->outs;
        var id = inst.id;
        var ty = inst.target_type;
        var align = inst.align;
        var length = inst.length;
        outs.puts(@"%$id = alloca $ty, $(length.value_type) ");
        _write_by_ref(length);
        outs.printf(" align %lu", align);
    }
    public override void visit_inst_load(IR.LoadSSA inst)
    {
        unowned var outs = _rt->outs;
        var id = inst.id;
        var ty = inst.value_type;
        var align = inst.align;
        var operand = inst.operand;
        var operandty = inst.source_type;
        outs.puts(@"%$id = load $ty, $operandty ");
        _write_by_ref(operand);
        outs.printf(", align %lu", align);
    }
    public override void visit_inst_store(IR.StoreSSA inst)
    {
        unowned var outs = _rt->outs;
        var align = inst.align;
        var srcty = inst.source_type;
        var dstty = inst.target_type;
        var src = inst.source;
        var dst = inst.target;
        outs.puts(@"store $srcty ");
        _write_by_ref(src);
        outs.puts(@", $dstty ");
        _write_by_ref(dst);
        outs.printf(", align %lu", align);
    }
    public override void visit_inst_return(IR.ReturnSSA inst)
    {
        unowned var outs = _rt->outs;
        var ty = inst.value_type;
        IR.Value retval = inst.retval;
        if (ty.is_void) {
            outs.puts("ret void");
        } else {
            outs.puts(@"ret $ty ");
            _write_by_ref(retval);
        }
    }
    public override void visit_inst_unreachable(IR.UnreachableSSA inst) {
        _rt->outs.puts("unreachable");
    }
    public override void visit_inst_jump(IR.JumpSSA inst) {
        _rt->outs.printf("br label %%%d", inst.target.id);
    }
    public override void visit_inst_branch(IR.BranchSSA inst)
    {
        unowned var  outs = _rt->outs;
        unowned Type cond_type = inst.condition.value_type;
        outs.puts(@"br $cond_type ");
        _write_by_ref(inst.condition);
        outs.printf(", label %%%d, label %%%d",
                    inst.if_true.id, inst.if_false.id);
    }
    public override void visit_inst_phi(IR.PhiSSA inst)
    {
        unowned var outs = _rt->outs;
        unowned var type = inst.value_type;
        int id = inst.id;
        outs.puts(@"%$id = phi $type ");
        uint cnt = 0;
        foreach (var entry in inst.from_map) {
            IR.Value   operand = entry.value.get_operand();
            IR.BasicBlock from = entry.key;
            outs.puts(cnt != 0? ", [ ": "[ ");
            cnt++;
            _write_by_ref(operand);
            outs.printf(",  %%%d ]", from.id);
        }
    }
    public override void visit_inst_index_ptr(IR.IndexPtrSSA inst)
    {
        unowned var outs = _rt->outs;
        var id = inst.id;
        var ity = inst.primary_target_type;
        var pty = inst.source.value_type;
        outs.puts(@"%$id = getelementptr inbounds $ity, $pty ");
        _write_by_ref(inst.source);
        foreach (var idx in inst.indices) {
            outs.puts(@", $(idx.index.value_type) ");
            _write_by_ref(idx.index);
        }
    }
    public override void visit_inst_index_extract(IR.IndexExtractSSA inst)
    {
        unowned var outs = _rt->outs;
        var id = inst.id;
        var srcty = inst.aggregate_type;
        var dstty = inst.index.value_type;
        outs.puts(@"%$id = extractelement $srcty ");
        _write_by_ref(inst.aggregate);
        outs.puts(@", $dstty ");
        _write_by_ref(inst.index);
    }
    public override void visit_inst_index_insert(IR.IndexInsertSSA inst)
    {
        unowned var outs = _rt->outs;
        var id = inst.id;
        var srcty = inst.aggregate_type;
        var dstty = inst.index.value_type;
        var elmty = inst.element_type;
        outs.puts(@"%$id = insertelement $elmty ");
        _write_by_ref(inst.element);
        outs.puts(@", $srcty ");
        _write_by_ref(inst.aggregate);
        outs.puts(@", $dstty ");
        _write_by_ref(inst.index);
    }

    private void _write_by_ref(IR.Value value)
    {
        if (value.shares_ref)
            value.accept(this);
        else if (value.isvalue_by_id(GLOBAL_OBJECT))
            _rt->outs.printf("@%s", static_cast<IR.GlobalObject>(value).name);
        else
            _rt->outs.printf("%%%d", value.id);
    }
    private void _wrap_indent()
    {
        uint indent_level = _rt->indent_level;
        unowned string space = _rt->space;
        unowned var outs = _rt->outs;
        outs.putchar('\n');
        for (uint i = 0; i < indent_level; i++)
            outs.puts(space);
    }

    public Writer(IR.Module module) {
        this.module = module;
    }

    public struct Runtime {
        IOutputStream   outs;
        uint    indent_level;
        string  space;
    }
}
