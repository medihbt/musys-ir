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
        /** 数组下标越界 */
        INDEX_OVERFLOW,
        NULL_PTR;
    }

    [CCode (cheader_filename="musys-backtrace.h")]
    public extern int print_backtrace();

    private void _crash_print_head()
    {
        stderr.printf("|================ [进程 %d 已崩溃] ================|\n",
                      stdc.getpid());
        stderr.puts  ("-----------------< 栈回溯 >-----------------\n");
        print_backtrace();
    }

    /**
     * 打印栈回溯, 然后报错崩溃. 一般与 critical() 函数配合使用.
     */
    [NoReturn]
    public void traced_abort()
    {
        stderr.printf("|================ [进程 %d 已崩溃] ================|\n",
                      stdc.getpid());
        print_backtrace();
        Process.abort();
    }

    [NoReturn, Diagnostics]
    public void crash(string msg, bool pauses = false)
    {
        _crash_print_head();
        stderr.puts("-----------------<  消息  >-----------------\n");
        stderr.puts(msg);
        if (pauses) {
            stderr.puts("请按回车键继续...\n");
            stdin.getc();
        } else {
            stderr.putc('\n');
        }
        Process.abort();
    }
    [NoReturn, Diagnostics]
    public void crash_err(Error e, string? extra_msg = null) {
        if (extra_msg == null)
            crash_fmt("Aborted error %s(%d): %s", e.domain.to_string(), e.code, e.message);
        else
            crash_fmt("Aborted error %s(%d): %s\n%s", e.domain.to_string(), e.code, e.message, extra_msg);
    }
    [NoReturn]
    public inline void crash_vfmt(string fmt, va_list ap)
    {
        _crash_print_head();
        stderr.puts("-----------------<  消息  >-----------------\n");
        stderr.vprintf(fmt, ap);
        stderr.puts("\n请按回车键继续...");
        stdin.getc();
        Process.abort();
    }
    [NoReturn, PrintfFormat, Diagnostics]
    public void crash_fmt(string fmt, ...) {
        crash_vfmt(fmt, va_list());
    }
}