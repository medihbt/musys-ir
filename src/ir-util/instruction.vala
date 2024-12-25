namespace Musys.IRUtil.Instruction {
    public bool ordered(IR.Instruction before, IR.Instruction after)
    {
        if (before.parent != after.parent) {
            crash_fmt("Requires instructions in the same basic block, but " +
                "`before(%p, id %d)` has parent %p (id %d), " +
                "`after(%p, id %d)` has parent %p (id %d), ",
                before, before.id, before.parent, before.parent.id,
                after,  after.id,  after.parent,  after.parent.id);
        }
        var before_it = before.modifier;
        var after_it = after.modifier;
        while (before_it.get() != after_it.get()) {
            if (before_it.next() == false)
                return false;
        }
        return true;
    }

    public bool may_write_memory(IR.Instruction inst)
    {
        switch (inst.opcode) {
        case STORE: case CALL: case DYN_CALL:
            return true;
        default:
            return false;
        }
    }

    public bool may_throw(IR.Instruction inst) {
        return false;
    }
    public bool will_return(IR.Instruction inst) {
        return true;
    }

    public bool may_have_side_effect(IR.Instruction inst)
    {
        return may_write_memory(inst) ||
               may_throw(inst) || !will_return(inst);
    }
}