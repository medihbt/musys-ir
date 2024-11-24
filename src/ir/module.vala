namespace Musys.IR {
    public class Module: Object {
        public TypeContext                       type_ctx  {get; private set;}
        public Gee.TreeMap<string, GlobalObject> global_def{get; private set;}
        public string   name   { get; set; }
        public Platform target { get; internal set; }

        public Module(string name, uint word_size = (uint)sizeof(pointer), Platform.Endian endian = LITTLE) {
            this.target = new Platform() {
                word_size_bytes = (uint8)word_size,
                ptr_size_bytes  = (uint8)word_size,
                endian = endian
            };
            this.name       = name;
            this.type_ctx   = new TypeContext(word_size);
            this.global_def = new Gee.TreeMap<string, GlobalObject>();
        }
        public Module.with_target(string name, Platform target) {
            this.target = target;
            this.name   = name;
            this.type_ctx   = new TypeContext(target.word_size_bytes);
            this.global_def = new Gee.TreeMap<string, GlobalObject>();
        }
    }
}
