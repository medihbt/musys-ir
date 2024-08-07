namespace Musys.IRUtil {
    public void number_module(IR.Module module)
    {
        foreach (var entry in module.global_def) {
            var gobj = entry.value;
            if (gobj is IR.Function)
                number_function(static_cast<IR.Function>(gobj));
        }
    }

    public void number_function(IR.Function fn)
    {

        int number = 0;
        foreach (var arg in fn.args) {
            arg.id = number;
            number++;
        }
        if (fn.is_extern)
            return;
        unowned var body = fn.body;
        IR.BasicBlock entry = body.entry;
        number = _number_basic_block(entry, number);
        foreach (var b in body) {
            if (b == entry)
                continue;
            number = _number_basic_block(b, number + 1);
        }
    }

    private int _number_basic_block(IR.BasicBlock block, int begin)
    {
        block.id = begin; begin++;
        foreach (var inst in block.instructions) {
            if (inst is IR.IBasicBlockTerminator || inst.value_type.is_void)
                continue;
            inst.id = begin;
            begin++;
        }
        return begin;
    }
}
