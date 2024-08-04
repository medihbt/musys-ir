namespace Musys.IR {
    public interface IValueVisitor {
        public virtual void visit_const_int       (ConstInt      value) {}
        public virtual void visit_const_float     (ConstFloat    value) {}
        public virtual void visit_const_data_zero (ConstDataZero value) {}
        public virtual void visit_array_expr      (ArrayExpr     value) {}
        public virtual void visit_ptr_null        (ConstPtrNull  value) {}
        public virtual void visit_undefined       (UndefinedValue udef) {}
        public virtual void visit_global_variable (GlobalVariable gvar) {}
        public virtual void visit_function        (Function       func) {}
        public virtual void visit_argument        (FuncArg        farg) {}
        public virtual void visit_basicblock      (BasicBlock    block) {}
        public virtual void visit_inst_binary     (BinarySSA      inst) {}
        public virtual void visit_inst_compare    (CompareSSA     inst) {}
        public virtual void visit_inst_unary      (UnaryOpSSA     inst) {}
        public virtual void visit_inst_cast       (CastSSA        inst) {}
        public virtual void visit_inst_call       (CallSSA        inst) {}
        public virtual void visit_inst_alloca     (AllocaSSA      inst) {}
        public virtual void visit_inst_dyn_alloca (DynAllocaSSA   inst) {}
        public virtual void visit_inst_load       (LoadSSA        inst) {}
        public virtual void visit_inst_store      (StoreSSA       inst) {}
        public virtual void visit_inst_unreachable(UnreachableSSA inst) {}
        public virtual void visit_inst_return     (ReturnSSA      inst) {}
        public virtual void visit_inst_jump       (JumpSSA        inst) {}
        public virtual void visit_inst_branch     (BranchSSA      inst) {}
        public virtual void visit_inst_phi        (PhiSSA         inst) {}
        public virtual void visit_inst_index_ptr  (IndexPtrSSA    inst) {}
        public virtual void visit_inst_index_extract(IndexExtractSSA inst) {}
        public virtual void visit_inst_index_insert (IndexInsertSSA  inst) {}
    }
}
