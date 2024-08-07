namespace Musys.IRUtil.BasicBlock {
    private IR.BasicBlock _split_raw_from_end(IR.BasicBlock old)
    {
        try {
            var tctx = old.value_type.type_ctx;
            var voidty = tctx.void_type;
            var jmpssa = new IR.JumpSSA.raw(voidty);
            var modif = old.terminator.modifier;
            var termi = modif.replace(jmpssa);
            var new_block = new IR.BasicBlock.with_terminator(
                termi as IR.IBasicBlockTerminator
            );
            new_block.plug_this_after(old);
            jmpssa.target = new_block;
            return new_block;
        } catch (IR.InstructionListErr e) {
            crash(e.message);
        }
    }
    public void replace_phi_from_in_succ(IR.BasicBlock oldblk, IR.BasicBlock newblk)
    {
        var termi = oldblk.terminator;
        if (termi.isvalue_by_id(RET_SSA) ||
            termi.isvalue_by_id(UNREACHABLE_SSA))
            return;
        termi.forEachTarget((block) => {
            foreach (var inst in block.instructions) {
                if (!inst.isvalue_by_id(PHI_SSA))
                    continue;
                var phi = static_cast<IR.PhiSSA>(inst);
                if (!phi.has_from(oldblk))
                    continue;
                IR.Value value = phi[oldblk];
                phi.remove_from(oldblk);
                phi.set_from(newblk, value);
            }
            return false;
        });
    }

    public IR.BasicBlock split_from_end(IR.BasicBlock old)
    {
        var after = _split_raw_from_end(old);
        replace_phi_from_in_succ(old, after);
        return after;
    }

    private IR.BasicBlock _split_after_modifier(IR.BasicBlock block, IR.InstructionList.Modifier modif)
    {
        try {
            IR.BasicBlock after = split_from_end(block);
            while (true) {
                var curr = modif;
                if (!curr.next())
                    break;
                IR.Instruction i = curr.get();
                if (i is IR.IBasicBlockTerminator)
                    break;
                curr.unplug();
                after.append(i);
            }
            return after;
        } catch (Error e) {
            crash(e.message);
        }
    }
    public IR.BasicBlock split_after(IR.Instruction ibefore)
    {
        if (!ibefore.is_attached()) {
            unowned string iklass = ibefore.get_class().get_name();
            unowned string opcode = ibefore.opcode.to_string();
            crash_fmt(
                {Log.FILE, Log.METHOD, Log.LINE},
                "Instruction(class %s, opcode %s) should be attached to Basic Block\n",
                iklass, opcode
            );
        }
        if (ibefore == ibefore.parent.terminator) {
            unowned string iklass = ibefore.get_class().get_name();
            unowned string opcode = ibefore.opcode.to_string();
            crash_fmt(
                {Log.FILE, Log.METHOD, Log.LINE},
                "Instruction(class %s, opcode %s) should be attached to Basic Block\n",
                iklass, opcode
            );
        }
        return _split_after_modifier(ibefore.parent, ibefore.modifier);
    }
    public IR.BasicBlock split_before(IR.Instruction iafter)
    {
        if (!iafter.is_attached()) {
            unowned string iklass = iafter.get_class().get_name();
            unowned string opcode = iafter.opcode.to_string();
            crash_fmt(
                {Log.FILE, Log.METHOD, Log.LINE},
                "Instruction(class %s, opcode %s) should be attached to Basic Block\n",
                iklass, opcode
            );
        }
        return _split_after_modifier(
            iafter.parent,
            IR.InstructionList.Modifier() {
                node = iafter._nodeof_this->_prev
            }
        );
    }
}
