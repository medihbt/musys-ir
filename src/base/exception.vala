namespace GLibC {
    [CCode (cname="backtrace", cheader_filename="execinfo.h")]
    public extern int backtrace(pointer []stack_buffer);

    [CCode (cname="backtrace_symbols", cheader_filename="execinfo.h")]
    public extern string *backtrace_symbols(pointer []stack_buffer);

    [CCode (cname="backtrace_symbols_fd", cheader_filename="execinfo.h")]
    public extern void backtrace_symbols_fd(pointer *stack_buffer, int len, int fd);

    [NoReturn]
    [CCode (cname="abort", cheader_filename="unistd.h")]
    public extern void abort();
}

namespace Musys {
    [CCode (has_type_id=false)]
    public struct SourceLocation {
        unowned string filename;
        unowned string method;
        int            line;

        [CCode (cname="__LINE__")]
        public extern const int    CLINE;
        [CCode (cname="__func__")]
        public extern const string CFUNC;
        [CCode (cname="__FILE__")]
        public extern const string CFILE;

        public SourceLocation.current(string filename = Musys.SourceLocation.CFILE,
                                      string method   = Musys.SourceLocation.CFUNC,
                                      int    line     = Musys.SourceLocation.CLINE) {
            this.filename = filename;
            this.method   = method;
            this.line     = line;
        }
    }

    public enum ErrLevel {
        INFO, DEBUG, WARNING, CRITICAL, FATAL;
    }
    public errordomain RuntimeErr {
        NULL_PTR;
    }

    public inline int print_backtrace()
    {
        pointer stack_buffer[32];
        int ret_nlayers = GLibC.backtrace(stack_buffer);
        GLibC.backtrace_symbols_fd((pointer*)stack_buffer, ret_nlayers, 2);
        return ret_nlayers;
    }

    [NoReturn]
    public void crash(string msg, bool pauses = true, SourceLocation loc = SourceLocation.current())
    {
        stderr.printf("|================ [进程 %s 已崩溃] ================|\n",
                      Environment.get_prgname());
        stderr.puts  ("-----------------<  位置  >-----------------\n");
        stderr.printf("源文件: %s\n行:   %d\n方法: %s\n", loc.filename, loc.line, loc.method);
        stderr.puts  ("-----------------< 栈回溯 >-----------------\n");
        print_backtrace();
        stderr.puts  ("-----------------<  消息  >-----------------\n");
        stderr.puts  (msg);
        if (pauses) {
            stderr.puts("请按回车键继续...");
            stdin.getc();
        }
        GLibC.abort();
    }
}