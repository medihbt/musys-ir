/**
 * === Machine Platform Representation ===
 *
 * Machine platforms for IR optimization.
 * 
 */
public class Musys.Platform {
    public uint8  word_size_bytes { get; set; }
    public uint8  ptr_size_bytes  { get; set; }
    public Endian endian { get; set; }

    public bool ptr_is_regular() {
        return word_size_bytes == ptr_size_bytes;
    }
    public bool ptr_fits_regular() {
        return word_size_bytes >= ptr_size_bytes;
    }

    public Platform.from(uint8 word_size, uint8 ptr_size, Endian endian) {
        this.word_size_bytes = word_size;
        this.ptr_size_bytes  = ptr_size;
        this.endian = endian;
    }
    public Platform.host() {
        this.from((uint8)sizeof(size_t), (uint8)sizeof(void*), Endian.Host());
    }
    public Platform.amd64()   { this.from(8, 8, LITTLE); }
    public Platform.riscv32() { this.from(4, 4, LITTLE); }
    public Platform.riscv64() { this.from(8, 8, LITTLE); }
    public Platform.arm32  (Endian endian = LITTLE) { this.from(4, 4, endian); }
    public Platform.aarch64(Endian endian = LITTLE) { this.from(8, 8, endian); }

    public enum Endian {
        LITTLE, BIG;

        [CCode (cname="MusysPlatformEndianHost")]
        public static Endian Host() {
            switch (ByteOrder.HOST) {
                case ByteOrder.BIG_ENDIAN:    return BIG;
                case ByteOrder.LITTLE_ENDIAN: return LITTLE;
                default: assert_not_reached();
            }
        }
        [CCode (cname="MusysPlatformEndianFromGLib")]
        public static Endian FromGLib(GLib.ByteOrder order) {
            switch (order) {
                case ByteOrder.BIG_ENDIAN:    return BIG;
                case ByteOrder.LITTLE_ENDIAN: return LITTLE;
                default: assert_not_reached();
            }
        }
        public GLib.ByteOrder to_glib() {
            switch (this) {
                case BIG:    return BIG_ENDIAN;
                case LITTLE: return LITTLE_ENDIAN;
                default:     assert_not_reached();
            }
        }
        public bool is_host() { return to_glib() == ByteOrder.HOST; }
    }
}
