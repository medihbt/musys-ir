public class Musys.IRUtil.DataFlowPrinter: IR.IValueVisitor {
    public unowned FileStream outs;
    public IR.Function        func;
    private int indent_level = 0;
    private void _wrap_indent()
    {
        outs.putc('\n');
        for (uint i = 0; i < indent_level; i++)
            outs.puts(": ");
    }

    /**
     * === 打印 use-def 结点树 ===
     * 你要调用的方法在这里：打印一个函数的控制流和数据流信息.
     */
    public void print(IR.Function func, FileStream outs = stdout)
    {
        this.outs = outs;
        this.func = func;
        this.indent_level = 0;
        _print_function(func);
    }

    private void _print_operand(int index, IR.Value operand)
    {
        if (operand.shares_ref) {
            operand.accept(this);
        } else if (operand.isvalue_by_id(GLOBAL_OBJECT)) {
            var gobj = (IR.GlobalObject)operand;
            outs.printf("@%s addr %p class %s", gobj.name, gobj, gobj.get_class().get_name());
        } else {
            outs.printf("%%%d addr %p class %s", operand.id, operand, operand.get_class().get_name());
        }
    }
    private void _print_instruction(IR.Instruction inst)
    {
        _wrap_indent();
        unowned var operands = inst.operands;
        var sau = inst.set_as_usee;
        outs.printf("Inst %%%03d (opcode %6s, %u operands, %d users used) class %s addr %p",
            inst.id, inst.opcode.get_name(),
            operands.length, sau.size,
            inst.get_class().get_name(), inst
        );
        indent_level++;
        _wrap_indent();
        outs.printf("Operands (%u operands)", operands.length);
        indent_level++;
        int index = 0;
        foreach (var use in operands) {
            IR.Value? op = use.usee;
            _wrap_indent(); index++;
            if (op == null) {
                outs.printf("[%d] = (nil)", index);
            } else {
                outs.printf("[%d] = %s ", index, strvty(op));
                _print_operand(index, op);
            }
        }
        indent_level--;

        _wrap_indent();
        outs.printf ("Users (%d users)", sau.size);
        indent_level++;
        foreach (var use in sau) {
            _wrap_indent();
            IR.User user = use.user;
            if (user.isvalue_by_id(INSTRUCTION)) {
                var iinst = (IR.Instruction)user;
                outs.printf("%%%d addr %p, opcode %s, class %s, type %s ",
                    iinst.id, iinst,
                    iinst.opcode.get_name(),
                    iinst.get_class().get_name(),
                    strvty(iinst));
            } else if (user.isvalue_by_id(GLOBAL_OBJECT)) {
                var gobj = (IR.GlobalObject)user;
                outs.printf("@%s addr %p, class %s, type %s",
                    gobj.name, gobj,
                    gobj.get_class().get_name(),
                    strvty(user));
            } else {
                outs.printf("%%%d addr %p, class %s, type %s",
                    user.id, user,
                    user.get_class().get_name(),
                    strvty(user));
            }
        }
        indent_level--;
        indent_level--;
    }
    private void _print_basicblock(IR.BasicBlock bb)
    {
        _wrap_indent();
        outs.printf("BasicBlock %%%d (addr %p, %ld outcome, %lu instructions)",
            bb.id, bb,
            (long)bb.terminator.ntargets,
            bb.instructions.length);
        indent_level++;
        foreach (var inst in bb.instructions)
            _print_instruction(inst);

        var termi = bb.terminator;
        this._wrap_indent();
        outs.printf("OutcomeBlocks (%ld blocks)", (long)termi.ntargets);
        indent_level++;
        int idx = 0;
        termi.foreach_target((bb) => {
            this._wrap_indent();
            this.outs.printf("[%d] = %%%d", idx, bb.id);
            idx++;
            return false;
        });
        indent_level--;
        indent_level--;
    }
    private void _print_function(IR.Function func)
    {
        _wrap_indent();
        outs.printf("Function @%s (addr %p, %d args) {",
            func.name, func, func.args.length);
        indent_level++;
        _wrap_indent(); outs.puts("Arguments {");
        indent_level++;
        for (int idx = 0; idx < func.args.length; idx++) {
            var arg = func.args[idx];
            _wrap_indent();
            outs.printf("[%d] = %%%03d (addr %p, type %s)",
                idx, arg.id, arg, strvty(arg));
        }
        indent_level--;
        _wrap_indent(); outs.puts("}");

        foreach (var bb in func.body)
            _print_basicblock(bb);
        indent_level--;
        _wrap_indent(); outs.puts("}");
    }

    public override void visit_const_int(IR.ConstInt value) {
        int64 i64_value = value.i64_value;
        outs.printf("Int 0x%llx (addr %p, dec(i64) %ld, dec(u64) %lu)",
            i64_value,
            value, i64_value, (uint64)i64_value);
    }
    public override void visit_const_float(IR.ConstFloat value) {
        double f64v = value.f64_value;
        uint64 u64v = *((uint64*)&f64v);
        outs.printf("Float %lg (addr %p, hex %llx)",
            f64v, value, u64v);
    }
    public override void visit_const_data_zero(IR.ConstDataZero value) {
        outs.printf("Zero (addr %p)", value);
    }
    public override void visit_array_expr(IR.ArrayExpr value)
    {
        if (value.is_zero) {
            outs.printf("ArrayExpr (addr %p, zeroinitializer) []", value);
            return;
        }
        outs.printf("ArrayExpr (addr %p, %d elems) [", value, value.elems.length);
        indent_level++;
        uint idx = 0;
        foreach (var elem in value.elems) {
            _wrap_indent();
            outs.printf("[%03u] = %s ", idx, strvty(elem));
            elem.accept(this);
            idx++;
        }
        indent_level--;
        _wrap_indent(); outs.puts("]");
    }
    public override void visit_struct_expr(IR.StructExpr value)
    {
        if (value.is_zero) {
            outs.printf("StructExpr (addr %p, zeroinitializer) {}", value);
            return;
        }
        outs.printf("StructExpr (addr %p, %d elems) {", value, value.elems.length);
        indent_level++;
        uint idx = 0;
        foreach (var elem in value.elems) {
            unowned string elemty = strvty(elem);
            _wrap_indent();
            outs.printf(".%03u = %s ", idx, elemty);
            elem.accept(this);
            idx++;
        }
        indent_level--;
        _wrap_indent(); outs.puts("}");
    }
    public override void visit_ptr_null(IR.ConstPtrNull value) { outs.puts("null"); }
    public override void visit_undefined(IR.UndefinedValue udef) {
        outs.puts(udef.is_poisonous? "poisonous": "undefined");
    }

    private static unowned string strvty(Musys.IR.Value? value)
    {
        if (value == null)
            return "<null value>";
        Type? type = value.value_type;
        if (type == null)
            return "<null type>";
        return type.to_string();
    }
}
