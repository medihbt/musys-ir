namespace stdc {
    [SimpleType]
    [CCode (cname="stdc_bool", cprefix="cbool_", cheader_filename="stdbool.h")]
    [BooleanType]
    public struct bool {
        public unowned string to_string() {
            return this? "true": "false";
        }
        public static bool parse(string str) {
            return str[0] == 'T' || str[0] == 't';
        }
    }

    [CCode (cname="getpid", cheader_filename="unistd.h")]
    public extern Pid getpid();
}
