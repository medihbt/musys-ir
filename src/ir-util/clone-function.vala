namespace MusysIR {
    public errordomain CloneFunctionErr {
        FUNCTION_IS_EXTERN,
        SYMBOL_NAME_EXISTS;
    }

    /**
     * 把函数 from 拷贝一份并命名为 to.
     *
     * 使用样例: 把函数 ``foo`` 拷贝一份，命名为 ``foo_1``; 然后再拷贝一次 ``foo_1`` 为 ``foo_2``,
     * 最后返回 foo_2.
     *
     * {{{
     * Function clone_foo(Module module, Function foo_func)
     * {
     *     var clone = new CloneFunction.from_module(module);
     *     try {
     *         Function foo1 = clone.run(foo_func, "foo_1");
     *         Function foo2 = clone.run(foo1, "foo_2");
     *         return foo_2;
     *     } catch (Error e) {
     *         crash_err(e);
     *     }
     * }
     * }}}
     *
     */
    public class CloneFunction: IValueVisitor {
        private Runtime       rt;
        private Module module;
        private TypeContext tctx;
        private Function from;
        private Function to;

        /**
         * ==== 构造函数: 这是你要调用的构造方法 ====
         */
        public CloneFunction.from_module(Module module) {
            this.module = module;
            this.tctx   = module.type_ctx;
            this.rt.init_clean(this);
        }

        /**
         * ==== 拷贝函数: 这是你要调用的函数接口 ====
         */
        public Function run(Function fn, string new_name, bool copy_attributes = false)
                throws Error, CloneFunctionErr, FuncBodyErr
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
        private void _raw_create(Function primary, string new_name)
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
            this.to = new Function.as_impl(primary.function_type, new_name);
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
            BasicBlock to_entry   = to.body.entry;
            LabelType     labelty    = to_entry.show_label_type();
            /* 首先, 拷贝整个基本块集合 */
            BasicBlock to_curr = to_entry;
            foreach (var bb in from.body) {
                if (bb == from.body.entry) {
                    rt.copy_map[bb] = to_entry;
                    continue;
                }
                var bb_to = new BasicBlock.with_unreachable(labelty);
                bb_to.plug_this_after(to_curr);
                rt.copy_map[bb] = bb_to;
                to_curr = bb_to;
            }

            /* 然后, 拷贝终止子 */
            foreach (var from_bb in from.body) {
                if (!from_bb.has_terminator())
                    continue;
                var to_bb = rt.copy_map[from_bb] as BasicBlock;
                _copy_terminator(from_bb, to_bb);
            }
        }
        void visit_basicblock(BasicBlock bb)
        {
            BasicBlock? ret = rt.find_copy(bb) as BasicBlock;
            if (ret != null) {
                rt.saved = ret;
                return;
            }
            crash_fmt("在指令拷贝之前, 所有基本块(控制流)都要拷贝完毕. 但是 %d (%p, %lu 条指令) 除外.\n",
                bb.id, bb, bb.instructions.length);
        }

    /* ================ [终止子] ================ */

        private void _copy_terminator(BasicBlock from_bb, BasicBlock to_bb)
                    throws InstructionListErr
        {
            rt.from_bb = from_bb;
            rt.to_bb   = to_bb;
            if (!from_bb.has_terminator()) {
                crash_fmt("Detected broken basic block %d(%p) from function @%s",
                    from_bb.id, from_bb, from.name
                );
            }
            from_bb.terminator.accept(this);
            var to_termi = rt.saved as IBasicBlockTerminator;
            to_bb.set_terminator_throw(to_termi);
            /* 保个险. 这个语句是为可能出现的 invoke 指令准备的. */
            if (unlikely(!to_termi.value_type.is_void))
                rt.copy_map[from_bb.terminator] = to_termi;
        }
        void visit_inst_jump(JumpSSA jmp_inst) {
            /* Terminator JumpSSA */
            BasicBlock from_target = jmp_inst.target;
            rt.saved = new JumpSSA(rt.find_copy(from_target) as BasicBlock);
        }
        void visit_inst_branch(BranchSSA br_inst)
        {
            /* Terminator BranchSSA */
            var to_false = (!)(rt.find_copy(br_inst.if_false) as BasicBlock);
            var to_true  = (!)(rt.find_copy(br_inst.if_true)  as BasicBlock);
            /* 指令的第一趟拷贝: 操作数引用不变 */
            rt.saved = new BranchSSA.with(br_inst.condition, to_false, to_true);
        }
        void visit_inst_return(ReturnSSA ret_inst) {
            /* Terminator ReturnSSA */
            rt.saved = new ReturnSSA(ret_inst.retval);
        }
        void visit_inst_switch(SwitchSSA inst)
        {
            /* Terminator SwitchSSA */
            var to_default = (!)(rt.find_copy(inst.default_target) as BasicBlock);
            var copy = new SwitchSSA.with_default(inst.condition, to_default);
            foreach (var ct in inst.view_cases()) {
                long case_n = ct.case_n;
                var  bb     = rt.find_copy(ct.target) as BasicBlock;
                copy.set_case(case_n, bb);
            }
            rt.saved = copy;
        }
        void visit_inst_unreachable(UnreachableSSA unreachable_inst) {
            /* Terminator UnreachableSSA */
            rt.saved = new UnreachableSSA(rt.to_bb);
        }

    /* ================ [普通指令] ================ */
        private void _copy_data_flow() throws Error
        {
            foreach (BasicBlock from_bb in from.body) {
                var from_insts = from_bb.instructions;
                if (from_insts.length <= 1)
                    continue;
                var to_bb = rt.find_copy(from_bb) as BasicBlock;
                rt.from_bb = from_bb;
                rt.to_bb   = to_bb;
                var to_termi = to_bb.terminator;
                var modifier = to_termi.modifier;
                /* 拷贝指令 */
                foreach (var inst in from_insts) {
                    if (inst is IBasicBlockTerminator)
                        continue;
                    inst.accept(this);
                    var to_inst = (!)(rt.saved as Instruction);
                    rt.copy_map[inst] = to_inst;
                    modifier.prepend(to_inst);
                }
            }
            _map_operands();
        }
        private void _map_operands() throws Error
        {
            foreach (BasicBlock to_bb in to.body) {
                var to_insts = to_bb.instructions;
                foreach (var inst in to_insts)
                    _map_replace_inst(inst);
            }
        }
        private void _map_replace_inst(Instruction inst) throws Error
        {
            foreach (var u in inst.operands)
                u.usee = (!)rt.find_copy(u.usee);
        }

        void visit_inst_phi(PhiSSA phi)
        {
            var ret = new PhiSSA.raw(phi.value_type);
            foreach (var entry in phi.from_map) {
                var from = entry.value;
                var to_from = rt.find_copy(from.from) as BasicBlock;
                assert_nonnull(to_from);
                ret[to_from] = from.get_operand();
            }
            rt.saved = ret;
        }
        void visit_inst_binary(BinarySSA binary_inst)
        {
            rt.saved = new BinarySSA.nocheck(
                binary_inst.opcode, binary_inst.value_type,
                binary_inst.lhs, binary_inst.rhs, binary_inst.is_signed);
        }
        void visit_inst_compare(CompareSSA inst) {
            var ret = new CompareSSA.raw(inst.opcode, inst.operand_type, inst.condition);
            ret.lhs = inst.lhs; ret.rhs = inst.rhs;
            rt.saved = ret;
        }
        void visit_inst_unary(UnaryOpSSA inst) {
            var ret = new UnaryOpSSA.raw(inst.opcode, inst.value_type);
            ret.operand = inst.operand;
            rt.saved = ret;
        }
        void visit_inst_cast(CastSSA inst) {
            var ret = new CastSSA.raw(inst.opcode, inst.value_type, inst.source_type);
            ret.operand = inst.operand;
            rt.saved = ret;
        }
        void visit_inst_call(CallSSA inst) {
            var ret = new CallSSA.raw(inst.callee_fn_type);
            _dup_inst_fn_call(inst, ret);
        }
        void visit_inst_dyn_call(DynCallSSA inst) {
            var ret = new DynCallSSA.raw(inst.callee_fn_type);
            _dup_inst_fn_call(inst, ret);
        }
        private void _dup_inst_fn_call(CallBase inst, CallBase ret)
        {
            ret.callee = inst.callee;
            unowned var from_uargs = inst.uargs;
            unowned var to_uargs   = ret.uargs;
            for (int i = 0; i < from_uargs.length; i++)
                to_uargs[i].arg = from_uargs[i].arg;
            rt.saved = ret;
        }

        void visit_inst_alloca(AllocaSSA alloca_inst) {
            rt.saved = new AllocaSSA.from_target(alloca_inst.target_type, alloca_inst.align);
        }
        void visit_inst_dyn_alloca(DynAllocaSSA inst) {
            rt.saved = new DynAllocaSSA.with_length(inst.target_type, inst.length, inst.align);
        }

        void visit_inst_load(LoadSSA inst) {
            rt.saved = new LoadSSA.from_ptr(inst.operand, inst.target_type, inst.align);
        }
        void visit_inst_store(StoreSSA inst) {
            rt.saved = new StoreSSA.from(inst.source, inst.target, inst.align);
        }

        void visit_inst_index_ptr(IndexPtrSSA inst) {
            rt.saved = new IndexPtrSSA.copy_nocheck(
                inst.primary_target_type, inst.indices);
        }
        void visit_inst_index_extract(IndexExtractSSA inst)
        {
            try {
                rt.saved = new IndexExtractSSA.from(inst.aggregate, inst.index);
            } catch (TypeMismatchErr e) {
                crash_err(e);
            }
        }
        void visit_inst_index_insert(IndexInsertSSA inst)
        {
            var ret = new IndexInsertSSA.raw(inst.aggregate_type) {
                aggregate = inst.aggregate,
                index     = inst.index,
                element   = inst.element
            };
            rt.saved = ret;
        }

        public struct Runtime {
            unowned CloneFunction         parent;
            HashTable<Value, Value> copy_map;
            Value saved;

            public void init_clean(CloneFunction parent)
            {
                this.parent = parent;
                if (copy_map != null)
                    copy_map.remove_all();
                else
                    copy_map = new HashTable<Value, Value>(null, null);
            }
            public bool needs_clone(Value value)
            {
                /* 常量数值和常量表达式共享引用, 不需要拷贝
                 * 全局量不在函数作用域内，不可拷贝 */
                if (value.isvalue_by_id(CONSTANT))
                    return false;
                if (value.isvalue_by_id(BASIC_BLOCK))
                    return static_cast<BasicBlock>(value).parent != parent.from;
                if (value.isvalue_by_id(INSTRUCTION))
                    return static_cast<Instruction>(value).parent.parent != parent.from;
                return true;
            }
            public Value? find_copy(Value value)
            {
                if (!needs_clone(value))
                    return value;
                if (value in copy_map)
                    return copy_map[value];
                return null;
            }

        /* ======== [指令流拷贝] ======== */

            /** 当前指令拷贝的源基本块 */
            BasicBlock from_bb;
            /** 当前指令拷贝的目标基本块 */
            BasicBlock to_bb;
        
        /* ======== [终止子拷贝] ========  */
        } // struct Runtime
    } // class CloneFunction
}
