namespace Musys.IRUtil {
    public errordomain CloneFunctionErr {
        FUNCTION_IS_EXTERN,
        SYMBOL_NAME_EXISTS;
    }

    public class CloneFunction: IR.IValueVisitor {
        public struct Runtime {
            unowned CloneFunction         parent;
            HashTable<IR.Value, IR.Value> copy_map;
            IR.Value saved;

            public void init_clean(CloneFunction parent)
            {
                this.parent = parent;
                if (copy_map != null)
                    copy_map.remove_all();
                else
                    copy_map = new HashTable<IR.Value, IR.Value>(null, null);
            }
            public bool needs_clone(IR.Value value)
            {
                /* 常量数值和常量表达式共享引用, 不需要拷贝
                 * 全局量不在函数作用域内，不可拷贝 */
                if (value.isvalue_by_id(CONSTANT))
                    return false;
                if (value.isvalue_by_id(BASIC_BLOCK))
                    return static_cast<IR.BasicBlock>(value).parent != parent.from;
                if (value.isvalue_by_id(INSTRUCTION))
                    return static_cast<IR.Instruction>(value).parent.parent != parent.from;
                return true;
            }
            public IR.Value? find_copy(IR.Value value)
            {
                if (!needs_clone(value))
                    return value;
                if (value in copy_map)
                    return copy_map[value];
                return null;
            }

        /* ======== [指令流拷贝] ======== */

            /** 当前指令拷贝的源基本块 */
            IR.BasicBlock from_bb;
            /** 当前指令拷贝的目标基本块 */
            IR.BasicBlock to_bb;
        
        /* ======== [终止子拷贝] ========  */
        } // struct Runtime

        private Runtime       rt;
        private IR.Module module;
        private TypeContext tctx;
        private IR.Function from;
        private IR.Function to;

        public CloneFunction.from_module(IR.Module module) {
            this.module = module;
            this.tctx   = module.type_ctx;
            this.rt.init_clean(this);
        }

        public IR.Function run(IR.Function fn, string new_name, bool copy_attributes = false)
                throws Error, CloneFunctionErr, IR.FuncBodyErr
        {
            if (copy_attributes)
                warning("Musys Value has not supported attributes yet");
            _raw_create(fn, new_name);
            _init_value_map();
            _register_arguments();
            _copy_control_flow();
            _copy_data_flow();
            return this.to;
        }
        private void _raw_create(IR.Function primary, string new_name)
                    throws CloneFunctionErr {
            if (primary.is_extern) {
                throw new CloneFunctionErr.FUNCTION_IS_EXTERN(
                    "Function @%s is extern", primary.name
                );
            }
            var globl_def = module.global_def;
            if (globl_def.has_key(new_name)) {
                var gdef = globl_def[new_name];
                throw new CloneFunctionErr.SYMBOL_NAME_EXISTS(
                    "Symbol @%s exists as `%s` (IR type %s)", new_name,
                    gdef.get_class().get_name(),
                    gdef.get_ptr_target().to_string()
                );
            }
            this.from = primary;
            this.to = new IR.Function.as_impl(primary.function_type, new_name);
            globl_def[new_name] = this.to;
        }
        private void _init_value_map() {
            rt.init_clean(this);
        }
        private void _register_arguments()
        {
            unowned var from_args = from.args;
            unowned var to_args  = to.args;
            for (int idx = 0; idx < from_args.length; idx++)
                rt.copy_map[from_args[idx]] = to_args[idx];
        }
        private void _copy_control_flow() throws Error
        {
            IR.BasicBlock to_entry   = to.body.entry;
            LabelType     labelty    = to_entry.show_label_type();
            /* 首先, 拷贝整个基本块集合 */
            IR.BasicBlock to_curr = to_entry;
            foreach (var bb in from.body) {
                if (bb == from.body.entry) {
                    rt.copy_map[bb] = to_entry;
                    continue;
                }
                var bb_to = new IR.BasicBlock.with_unreachable(labelty);
                bb_to.plug_this_after(to_curr);
                rt.copy_map[bb] = bb_to;
                to_curr = bb_to;
            }

            /* 然后, 拷贝终止子 */
            foreach (var from_bb in from.body) {
                if (!from_bb.has_terminator())
                    continue;
                var to_bb = rt.copy_map[from_bb] as IR.BasicBlock;
                _copy_terminator(from_bb, to_bb);
            }
        }
        void visit_basicblock(IR.BasicBlock bb)
        {
            IR.BasicBlock? ret = rt.find_copy(bb) as IR.BasicBlock;
            if (ret != null) {
                rt.saved = ret;
                return;
            }
            crash_fmt("在指令拷贝之前, 所有基本块(控制流)都要拷贝完毕. 但是 %d (%p, %lu 条指令) 除外.\n",
                bb.id, bb, bb.instructions.length);
        }

    /* ================ [终止子] ================ */

        private void _copy_terminator(IR.BasicBlock from_bb, IR.BasicBlock to_bb)
                    throws IR.InstructionListErr
        {
            rt.from_bb = from_bb;
            rt.to_bb   = to_bb;
            if (!from_bb.has_terminator()) {
                crash_fmt("Detected broken basic block %d(%p) from function @%s",
                    from_bb.id, from_bb, from.name
                );
            }
            from_bb.terminator.accept(this);
            var to_termi = rt.saved as IR.IBasicBlockTerminator;
            to_bb.set_terminator_throw(to_termi);
            /* 保个险. 这个语句是为可能出现的 invoke 指令准备的. */
            if (unlikely(!to_termi.value_type.is_void))
                rt.copy_map[from_bb.terminator] = to_termi;
        }
        void visit_inst_jump(IR.JumpSSA jmp_inst) {
            /* Terminator JumpSSA */
            IR.BasicBlock from_target = jmp_inst.target;
            rt.saved = new IR.JumpSSA(rt.find_copy(from_target) as IR.BasicBlock);
        }
        void visit_inst_branch(IR.BranchSSA br_inst)
        {
            /* Terminator BranchSSA */
            var to_false = (!)(rt.find_copy(br_inst.if_false) as IR.BasicBlock);
            var to_true  = (!)(rt.find_copy(br_inst.if_true)  as IR.BasicBlock);
            /* 指令的第一趟拷贝: 操作数引用不变 */
            rt.saved = new IR.BranchSSA.with(br_inst.condition, to_false, to_true);
        }
        void visit_inst_return(IR.ReturnSSA ret_inst) {
            /* Terminator ReturnSSA */
            rt.saved = new IR.ReturnSSA(ret_inst.retval);
        }
        void visit_inst_unreachable(IR.UnreachableSSA unreachable_inst) {
            /* Terminator UnreachableSSA */
            rt.saved = new IR.UnreachableSSA(rt.to_bb);
        }

    /* ================ [普通指令] ================ */
        private void _copy_data_flow() throws Error
        {
            foreach (IR.BasicBlock from_bb in from.body) {
                var from_insts = from_bb.instructions;
                if (from_insts.length <= 1)
                    continue;
                var to_bb = rt.find_copy(from_bb) as IR.BasicBlock;
                rt.from_bb = from_bb;
                rt.to_bb   = to_bb;
                var to_termi = to_bb.terminator;
                var modifier = to_termi.modifier;
                /* 拷贝指令 */
                foreach (var inst in from_insts) {
                    if (inst is IR.IBasicBlockTerminator)
                        continue;
                    inst.accept(this);
                    var to_inst = (!)(rt.saved as IR.Instruction);
                    rt.copy_map[inst] = to_inst;
                    modifier.prepend(to_inst);
                }
            }
            _map_operands();
        }
        private void _map_operands() throws Error
        {
            foreach (IR.BasicBlock to_bb in to.body) {
                var to_insts = to_bb.instructions;
                foreach (var inst in to_insts)
                    _map_replace_inst(inst);
            }
        }
        private void _map_replace_inst(IR.Instruction inst) throws Error
        {
            foreach (var u in inst.operands)
                u.usee = (!)rt.find_copy(u.usee);
        }

        void visit_inst_phi(IR.PhiSSA phi)
        {
            var ret = new IR.PhiSSA.raw(phi.value_type);
            foreach (var entry in phi.from_map) {
                var from = entry.value;
                var to_from = rt.find_copy(from.from) as IR.BasicBlock;
                assert_nonnull(to_from);
                ret[to_from] = from.get_operand();
            }
            rt.saved = ret;
        }
        void visit_inst_binary(IR.BinarySSA binary_inst)
        {
            rt.saved = new IR.BinarySSA.nocheck(
                binary_inst.opcode, binary_inst.value_type,
                binary_inst.lhs, binary_inst.rhs, binary_inst.is_signed);
        }
        void visit_inst_compare(IR.CompareSSA inst) {
            var ret = new IR.CompareSSA.raw(inst.opcode, inst.operand_type, inst.condition);
            ret.lhs = inst.lhs; ret.rhs = inst.rhs;
            rt.saved = ret;
        }
        void visit_inst_unary(IR.UnaryOpSSA inst) {
            var ret = new IR.UnaryOpSSA.raw(inst.opcode, inst.value_type);
            ret.operand = inst.operand;
            rt.saved = ret;
        }
        void visit_inst_cast(IR.CastSSA inst) {
            var ret = new IR.CastSSA.raw(inst.opcode, inst.value_type, inst.source_type);
            ret.operand = inst.operand;
            rt.saved = ret;
        }
        void visit_inst_call(IR.CallSSA inst) {
            var ret = new IR.CallSSA.raw(inst.callee_fn_type);
            _dup_inst_fn_call(inst, ret);
        }
        void visit_inst_dyn_call(IR.DynCallSSA inst) {
            var ret = new IR.DynCallSSA.raw(inst.callee_fn_type);
            _dup_inst_fn_call(inst, ret);
        }
        private void _dup_inst_fn_call(IR.CallBase inst, IR.CallBase ret)
        {
            ret.callee = inst.callee;
            unowned var from_uargs = inst.uargs;
            unowned var to_uargs   = ret.uargs;
            for (int i = 0; i < from_uargs.length; i++)
                to_uargs[i].arg = from_uargs[i].arg;
            rt.saved = ret;
        }

        void visit_inst_alloca(IR.AllocaSSA alloca_inst) {
            rt.saved = new IR.AllocaSSA.from_target(alloca_inst.target_type, alloca_inst.align);
        }
        void visit_inst_dyn_alloca(IR.DynAllocaSSA inst) {
            rt.saved = new IR.DynAllocaSSA.with_length(inst.target_type, inst.length, inst.align);
        }

        void visit_inst_load(IR.LoadSSA inst) {
            rt.saved = new IR.LoadSSA.from_ptr(inst.operand, inst.target_type, inst.align);
        }
        void visit_inst_store(IR.StoreSSA inst) {
            rt.saved = new IR.StoreSSA.from(inst.source, inst.target, inst.align);
        }

        void visit_inst_index_ptr(IR.IndexPtrSSA inst) {
            rt.saved = new IR.IndexPtrSSA.copy_nocheck(
                inst.primary_target_type, inst.indices);
        }
        void visit_inst_index_extract(IR.IndexExtractSSA inst)
        {
            try {
                rt.saved = new IR.IndexExtractSSA.from(inst.aggregate, inst.index);
            } catch (TypeMismatchErr e) {
                crash_err(e);
            }
        }
        void visit_inst_index_insert(IR.IndexInsertSSA inst)
        {
            var ret = new IR.IndexInsertSSA.raw(inst.aggregate_type) {
                aggregate = inst.aggregate,
                index     = inst.index,
                element   = inst.element
            };
            rt.saved = ret;
        }
    } // class CloneFunction
}
