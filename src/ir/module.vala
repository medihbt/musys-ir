namespace Musys.IR {
    public class Module: Object {
        public TypeContext                       type_ctx  {get; private set;}
        public Gee.TreeMap<string, GlobalObject> global_def{get; private set;}
        public string name{get;set;}

        public Module(string name, uint word_size = (uint)sizeof(pointer)) {
            this.name       = name;
            this.type_ctx   = new TypeContext(word_size);
            this.global_def = new Gee.TreeMap<string, GlobalObject>();
        }
    }
}
