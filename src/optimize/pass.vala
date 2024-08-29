namespace Musys.IROpt {
    /** `Pass` - 优化器基类 */
    public abstract class Pass: Object {
        public enum Kind {
            OPTIMIZE_PASS, ANALYSIS_PASS;
        }
        public Kind kind{get;set;}
        public abstract void clear_context();

        protected Pass.C1(Kind kind) {
            this.kind = kind;
        }
    }

    /** `FunctionPass` - 运行在函数上的优化器 */
    public abstract class FunctionPass: Pass {
        protected IR.Function _curr_function;
        public abstract void  run_on_function(IR.Function fn);

        protected FunctionPass.C1(Kind kind) {
            base.C1(kind);
        }
    }

    /** `ModulePass` - 运行在编译单元上的优化器 */
    public abstract class ModulePass: Pass {
        protected IR.Module  _curr_module;
        public abstract void run_on_module(IR.Module module);

        protected ModulePass.C1(Kind kind) {
            base.C1(kind);
        }
    }
}
