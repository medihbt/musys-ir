namespace Musys.IRUtil {
    public void number_module(IR.Module module)
    {
        foreach (var entry in module.global_def) {
            var gobj = entry.value;
            if (gobj is IR.Function)
                number_function(static_cast<IR.Function>(gobj));
        }
    }

    [Flags]
    public enum NumberValueFlags {
        VOID_TERMINATOR, NONVOID_TERMINATOR,
        VOID_MID_INST,   NONVOID_MID_INST,
        VOID_INST    = 5,
        NONVOID_INST = 6,
        ALL = 7;
    }

    public int number_function(IR.Function fn, NumberValueFlags flags = 0)
    {
        int number = 0;
        foreach (var arg in fn.args) {
            arg.id = number;
            number++;
        }
        if (fn.is_extern)
            return number;
        unowned var body = fn.body;
        IR.BasicBlock entry = body._entry;
        number = _number_basic_block(entry, number, flags);
        foreach (var b in body) {
            if (b == entry)
                continue;
            number = _number_basic_block(b, number + 1, flags);
        }
        return number;
    }

    private int _number_basic_block(IR.BasicBlock block, int begin, NumberValueFlags flags)
    {
        block.id = begin; begin++;
        foreach (var inst in block.instructions) {
            if (!_instruction_should_number(inst, flags))
                continue;
            inst.id = begin; begin++;
        }
        return begin;
    }
    private bool _instruction_should_number(IR.Instruction inst, NumberValueFlags flags)
    {
        bool is_termi = inst.isvalue_by_id(IBASIC_BLOCK_TERMINATOR);
        bool is_void  = inst.value_type.is_void;
        if (!is_termi && !is_void)
            return true;
        if (!is_termi && is_void)
            return (flags & NumberValueFlags.VOID_MID_INST) != 0;
        if (is_termi && !is_void)
            return (flags & NumberValueFlags.NONVOID_TERMINATOR) != 0;
        return (flags & NumberValueFlags.VOID_TERMINATOR) != 0;
    }
}
