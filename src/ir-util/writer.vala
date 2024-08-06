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
        public override void visit_function(IR.Function func)
        {
            unowned var    outs = _rt->outs;
            unowned string define = func.is_extern   ? "declare":  "define";
            unowned string visibl = func.is_internal ? "internal": "dso_local"; 
            outs.write_str(@"$define $visibl $(func.return_type) @$(func.name) (");

            unowned var args = func.args;
            for (uint i = 0; i < args.length; i++) {
                if (i != 0)
                    outs.write_str(", ");
                unowned var arg = args[i];
                outs.write_str(@"$(arg.value_type) %$(arg.id)");
            }
            if (func.is_extern) {
                outs.write_str(")");
                return;
            }

            outs.write_str(") {");
            var entry = func.body.entry;
            _wrap_indent();
            this.visit_basicblock(entry);
            foreach (IR.BasicBlock b in func.body) {
                if (b == entry)
                    continue;
                _wrap_indent();
                this.visit_basicblock(b);
            }
            outs.write_str("\n}");
            _wrap_indent();
        }
        public override void visit_global_variable(IR.GlobalVariable gvar)
        {
            unowned var    outs = _rt->outs;
            unowned string define = gvar.is_extern   ? "declare":  "define";
            unowned string visibl = gvar.is_internal ? "internal": "dso_local";
            outs.write_str(@"@$(gvar.id) = $define $visibl $(gvar.ptr_type.target)");
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
                var id = inst.id;
                var opcode = inst.opcode;
                unowned var inst_klass = inst.get_class().get_name();
                unowned var type = inst.value_type.to_string();
                outs.write_str(@"inst $id opcode $opcode class $inst_klass type $type");
            }
            _rt->indent_level--;
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
                outs.write_str(space);
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
