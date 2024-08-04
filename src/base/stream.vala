namespace Musys {
    public interface IOutputStream: Object {
        public abstract size_t write_buf(uint8* buf, size_t size);
        public virtual  void   putchar(char c) {
            write_buf(&c, 1);
        }
        public virtual  void   vprintf(string fmt, va_list ap) {
            write_str(fmt.vprintf(ap));
        }
        public size_t write_str(string str) {
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
        public override void putchar(char c) { file.putc(c); }
        public override void vprintf(string fmt, va_list ap) {
            file.vprintf(fmt, ap);
        }
        public FileOutStream(GLib.FileStream file) {
            this.file = file;
        }
    }
}
