namespace Musys {
    public interface IOutputStream: Object {
        public abstract size_t write_buf(uint8* buf, size_t size);
        public virtual  void   putchar(char c) {
            write_buf(&c, 1);
        }
        public virtual  void   vprintf(string fmt, va_list ap) {
            puts(fmt.vprintf(ap));
        }
        public virtual  size_t puts(string str) {
            return write_buf(str, str.length);
        }
        [PrintfFormat]
        public inline void printf(string fmt, ...) {
            vprintf(fmt, va_list());
        }
    }

    public class FileOutStream: Object, IOutputStream {
        public unowned GLib.FileStream file;
        public size_t write_buf(uint8 *buf, size_t size) {
            return file.write((uint8[])buf, size);
        }
        public override size_t puts(string str) {
            return file.puts(str);
        }
        public override void putchar(char c) { file.putc(c); }
        public override void vprintf(string fmt, va_list ap) {
            file.vprintf(fmt, ap);
        }
        public FileOutStream(GLib.FileStream file) {
            this.file = file;
        }
    }

    public class StringOutStream: Object, IOutputStream {
        public GLib.StringBuilder str_builder = new StringBuilder();
        public size_t write_buf(uint8* buf, size_t size) {
            str_builder.append_len((string)buf, (ssize_t)size);
            return size;
        }
        public override size_t puts(string str) {
            ssize_t len0 = str_builder.len;
            str_builder.append(str);
            return str_builder.len - len0;
        }
        public override void putchar(char c) {
            str_builder.append_c(c);
        }
        public override void vprintf(string fmt, va_list ap) {
            str_builder.append_vprintf(fmt, ap);
        }
    }
}
