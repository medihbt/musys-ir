namespace Musys.IR {
    public class GlobalVariable: GlobalObject {
        public Constant    init_content{get;set;}

        [CCode(notify=false)]
        public override bool is_mutable{get;set;}
        public override bool is_extern {
            get { return init_content == null; }
        }
        public size_t align{get;set;}

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

        public GlobalVariable.extern(Type content_type, string name) {
            base.C1(GLOBAL_VARIABLE, content_type, name, false);
            this.align  = content_type.instance_align;
            _is_mutable = true;
            _init_content = null;
        }
        public GlobalVariable.define(Type content_type, string name, bool is_internal = false)
        {
            base.C1(GLOBAL_VARIABLE, content_type, name, is_internal);
            _is_mutable   = true;
            this.align    = content_type.instance_align;
            _init_content = Constant.CreateZeroOrUndefined(content_type);
        }
        class construct { _istype[TID.GLOBAL_VARIABLE] = true; }
    }
}
