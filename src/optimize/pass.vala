namespace Musys.IROpti {
    /** `Pass` - 优化器基类 */
    public abstract class Pass: Object {
        public enum Kind {
            OPTIMIZE_PASS, ANALYSIS_PASS;
        }

        public    size_t class_id { get { return _class_id; } }
        protected class  size_t _class_id = 0;
        protected static size_t _max_id   = 0;
        protected static Mutex  _max_id_mutex = Mutex();

        public string class_description {
            get { return _class_description ?? "<unnamed pass>"; }
        }
        protected class string _class_description;

        public Kind kind{get;set;}
        public abstract void clear_context();

        protected Pass.C1(Kind kind) {
            this.kind = kind;
        }
        class construct { _klass_init_id(); }
        class void _klass_init_id() {
            _max_id_mutex.lock();
            _max_id++;
            _class_id = _max_id;
            _max_id_mutex.unlock();
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
