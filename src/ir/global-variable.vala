namespace Musys.IR {
    public class GlobalVariable: GlobalObject {
        public Constant    init_content{get;set;}
        public override bool is_mutable{get;set;}
        public override bool is_extern {
            get { return init_content == null; }
        }

        public override bool enable_impl() {
            try {
                init_content  = create_const_zero(content_type);
            } catch (TypeMismatchErr.NOT_INSTANTANEOUS e) {
                _init_content = new UndefinedValue(content_type, false);
            } catch (Error e) {
                crash(e.message);
            }
            return true;
        }
        public override bool disable_impl() {
            init_content = null; return true;
        }
        public override void accept(IValueVisitor visitor) {
            visitor.visit_global_variable(this);
        }

        public GlobalVariable.extern(PointerType type) {
            base.C1(GLOBAL_VARIABLE, type, false);
            _init_content = null;
        }
        public GlobalVariable.define(PointerType type, bool is_internal = false)
        {
            base.C1(GLOBAL_VARIABLE, type, false);
            try {
                _init_content = create_const_zero(type.target);
            } catch (TypeMismatchErr.NOT_INSTANTANEOUS e) {
                _init_content = new UndefinedValue(type.target, false);
            } catch (TypeMismatchErr e) {
                crash("TypemismatchErr message %s\n".printf(e.message));
            }
        }
    }
}
