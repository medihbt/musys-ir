[CCode(gir_namespace="Musys", gir_version="0.0.1")]
namespace Musys.IRUtil.BasicBlock {
    public errordomain CheckErr {
        GOT_PHI_IN_MIDDLE;
    }

    /** **检查函数**: PHI 指令必须在基本块的开头, **否则报错**
     * - @param `block` 等待检查的基本块
     * - @param `out last_phi` 正常情况下输出基本块的最后一条
     *   Phi 指令迭代器, 否则输出位置放错的那条 Phi 指令. 倘若
     *   基本块没有 Phi 指令, 则输出一个不可用的迭代器. */
    public void check_phi_on_top(IR.BasicBlock block,
                                 out IR.InstructionList.Iterator last_phi)
                throws CheckErr
    {
        var iter = block.instructions.iterator();
        last_phi = iter;
        bool phi_ends = false;
        uint inst_order = 0;
        while (iter.next() == true) {
            IR.Instruction inst = iter.get();
            bool inst_phi = inst is IR.PhiSSA;

            /* 在开头 PHI 指令段结束后再次出现的 PHI 指令是非法的 */
            if (phi_ends && inst_phi) {
                last_phi = iter;
                throw new CheckErr.GOT_PHI_IN_MIDDLE (
                    "Basicblock %p instructon order %u",
                    block, inst_order
                );
            }

            /* 位于 PHI 指令段的末尾时, 要存一份 PHI作为终止 */
            if (!phi_ends && !inst_phi) {
                phi_ends = true;
                last_phi = iter.get_prev();
            }
        }
    }

    public IR.BasicBlock split_raw_from_end(IR.BasicBlock old)
    {
        try {
            var jmpssa = new IR.JumpSSA.raw(old.value_type.type_ctx.void_type);
            var modif = old.terminator.modifier;
            var termi = modif.replace(jmpssa);
            var new_block = new IR.BasicBlock.with_terminator(termi as IR.IBasicBlockTerminator);
            new_block.plug_this_after(old);
            jmpssa.target = new_block;
            return new_block;
        } catch (IR.InstructionListErr e) {
            crash_err(e);
        }
    }
    internal void replace_phi_from_in_succ(IR.BasicBlock oldbb, IR.BasicBlock oldbb_succ)
    {
        var termi = oldbb_succ.terminator;
        if (termi.isvalue_by_id(RET_SSA) ||
            termi.isvalue_by_id(UNREACHABLE_SSA))
            return;
        termi.forEachTarget((block) => {
            foreach (var inst in block.instructions) {
                if (!(inst is IR.PhiSSA))
                    continue;
                var phi = static_cast<IR.PhiSSA>(inst);
                if (!phi.has_from(oldbb))
                    continue;
                IR.Value value = phi[oldbb];
                phi.remove_from(oldbb);
                phi.set_from(oldbb_succ, value);
            }
            return false;
        });
    }
    public IR.BasicBlock split_from_end(IR.BasicBlock old)
    {
        var after = split_raw_from_end(old);
        replace_phi_from_in_succ(old, after);
        return after;
    }

    public abstract class AbstractSplitter: Object {
        public IR.BasicBlock old_bb;
        public IR.BasicBlock new_bb;

        public void split_after_modifier(IR.InstructionList.Modifier modif) throws Error
        {
            if (modif.node == null || modif.list == null)
                crash_fmt({Log.FILE, Log.METHOD, Log.LINE}, "Modifier NOT attached to any basic block\n");
            old_bb = modif.list.parent;

            /* Musys 要求 PHI 指令位于基本块头部且不可拆分, 因此需要跳过 PHI 指令 */
            while (modif.get().isvalue_by_id(PHI_SSA)) {
                foreach_check_phi(static_cast<IR.PhiSSA>(modif.get()));
                bool has_next = modif.next();
                assert(has_next);
            }

            /* 拆分基本块, 并且执行 on_raw_split 操作 */
            this.split_raw_from_end();
            replace_phi_from_in_succ(old_bb, new_bb);

            /* 搬移指令 */
            while (true) {
                IR.InstructionList.Modifier next = modif.get_next();
                if (unlikely(!next.is_available())) {
                    crash_fmt({Log.FILE, Log.METHOD, Log.LINE},
                        "InstructionList position %p next not available",
                        modif.node);
                }
                if (next.get().isvalue_by_id(IBASIC_BLOCK_TERMINATOR))
                    break;
                IR.Instruction inst = next.unplug();
                new_bb.append(inst);
            }
            on_complete();
        }

        public void split_after(IR.Instruction ibefore) throws Error
        {
            if (!ibefore.is_attached() ||
                ibefore == ibefore.parent.terminator) {
                unowned string iklass = ibefore.get_class().get_name();
                unowned string opcode = ibefore.opcode.to_string();
                crash_fmt(
                    {Log.FILE, Log.METHOD, Log.LINE},
                    "Instruction(class %s, opcode %s) should be attached to Basic Block\n",
                    iklass, opcode
                );
            }
            split_after_modifier(ibefore.modifier);
        }
        public void split_before(IR.Instruction iafter) throws Error
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
            split_after_modifier(iafter.modifier.get_prev());
        }
        public void split_from_end(IR.BasicBlock old) throws Error
        {
            this.old_bb = old;
            split_raw_from_end();
            replace_phi_from_in_succ(old_bb, new_bb);
        }

        /** PHI 指令检查函数. 当检查不过关时请抛一个异常. */
        protected virtual void foreach_check_phi(IR.PhiSSA phi)
                               throws Error {}
        /** 在新基本块诞生、控制流改变，但是数据流还没修正、所有其他指令时触发的函数. */
        protected virtual void on_raw_split(IR.JumpSSA connection,
                                            IR.IBasicBlockTerminator old_terminator)
                               throws Error {}
        /** 在基本块拆分完成后触发的函数 */
        protected virtual void on_complete() throws Error {}

        protected void split_raw_from_end() throws Error
        {
            IR.JumpSSA               jmpssa = null;
            IR.IBasicBlockTerminator itermi = null;
            try {
                jmpssa = new IR.JumpSSA.raw(old_bb.value_type.type_ctx.void_type);
                var modif = old_bb.terminator.modifier;
                itermi = modif.replace(jmpssa) as IR.IBasicBlockTerminator;
                var new_block = new IR.BasicBlock.with_terminator(itermi);
                new_block.plug_this_after(old_bb);
                jmpssa.target = new_block;
                new_bb = new_block;
            } catch (IR.InstructionListErr e) {
                crash_err(e);
            }
            on_raw_split(jmpssa, itermi);
        }
    }

    public class RawSplitter: AbstractSplitter {
#   if MUSYS_DEBUG_OUTPUT_BB_SPLIT
        protected override void on_complete()
        {
            var termi = new_bb.terminator;
            print("Complete: this %p, BasicBlock [%p-%p], terminator [%p opcode %s class %s]\n",
                  this, old_bb, new_bb,
                  termi, termi.opcode.get_name(),
                  termi.get_class().get_name());
        }
#   endif
    }
}
