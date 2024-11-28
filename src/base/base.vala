namespace Musys {
    [CCode (simple_generics=true, cheader_filename="musys-base.h")]
    public extern unowned T static_cast<T>(void *u);

    public enum ForeachResult {
        CONTINUE, STOP;

        public bool to_gee()   { return this == CONTINUE; }
        public bool to_musys() { return this == STOP; }
        [CCode (cname="MusysForeachResultFromGee")]
        public static ForeachResult FromGee(bool continues) {
            return continues? CONTINUE: STOP;
        }
        [CCode (cname="MusysForeachResultFromMusys")]
        public static ForeachResult FromMusys(bool stops) {
            return stops? STOP: CONTINUE;
        }
    } // public enum ForeachResult
}
