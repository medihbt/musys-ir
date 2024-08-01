namespace Musys {
    public struct APInt {
        int64 data;
        uint8 bits;

        public int64 nmask { get { return   0xFFFFFFFFFFFFFFFF << bits;  } }
        public int64 pmask { get { return ~(0xFFFFFFFFFFFFFFFF << bits); } }
        public APInt.from_i64(int64 data, uint8 bits)
        {
            this.bits = bits;
            this.data = data & pmask;
        }
        public APInt.zero(uint8 bits)
        {
            this.bits = bits;
            this.data = 0;
        }
        public int64  i64_value {
            get { return (data & (0x1 << bits >> 1)) != 0 ? (data | nmask): data; }
            set { data = i64_value & pmask; }
        }
        public uint64 u64_value {
            get { return data; }
            set { data = i64_value & pmask; }
        }
    }
}