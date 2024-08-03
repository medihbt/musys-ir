namespace Musys.IR {
    public class Module: Object {
        public TypeContext                       type_ctx  {get; private set;}
        public Gee.TreeMap<string, GlobalObject> global_def{get; private set;}

        public Module(uint word_size = (uint)sizeof(pointer)) {
            this.type_ctx   = new TypeContext(word_size);
            this.global_def = new Gee.TreeMap<string, GlobalObject>();
        }
    }
}