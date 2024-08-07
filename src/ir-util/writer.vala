namespace Musys.IRUtil {
    public class Writer: IR.IValueVisitor {
        private Runtime  *_rt;
        public  IR.Module module;

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
                if (cnt != 0)
                    outs.puts(", ");
                _write_by_ref(elem);
            }
            outs.puts(" ]");
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
            unowned string define = gvar.is_extern   ? "declare":  "define";
            unowned string visibl = gvar.is_internal ? "internal": "dso_local";
            outs.puts(@"@$(gvar.name) = $define $visibl $(gvar.ptr_type.target)");
            if (gvar.init_content != null) {
                outs.putchar(' ');
                _write_by_ref(gvar.init_content);
            }
            outs.printf(", align %lu\n", gvar.align);
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
        public override void visit_inst_compare(IR.CompareSSA inst)
        {
            unowned var  outs = _rt->outs;
            unowned string operandty = inst.operand_type.name;
            unowned string opcode = inst.opcode == ICMP ? "icmp": "fcmp";
            unowned var condition = inst.condition;
            outs.puts(@"%$(inst.id) = $opcode $condition, $operandty $(inst.lhs.id), $(inst.rhs.id)");
        }

        private void _write_by_ref(IR.Value value)
        {
            if (value.shares_ref)
                value.accept(this);
            else if (value.isvalue_by_id(GLOBAL_OBJECT))
                _rt->outs.printf("@%d", value.id);
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
}
