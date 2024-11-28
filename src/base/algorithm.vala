namespace Musys {
    [CCode (cheader_filename="musys-base.h")]
    public extern bool is_power_of_2(size_t value);

    [CCode (cheader_filename="musys-base.h")]
    public extern bool is_power_of_2_nonzero(size_t value);

    [CCode (cheader_filename="musys-base.h")]
    public extern size_t fill_to(size_t x, size_t mod);

    [CCode (cheader_filename="musys-base.h")]
    public extern size_t fill_to_pwr_of_2(size_t x);

    public int ptrcmp(void* l, void* r) {
        var nl = (intptr)l;
        var nr = (intptr)r;
        if (nl < nr)      return -1;
        else if (nl > nr) return  1;
        else              return  0;
    }
    public int longcmp(long l, long r) {
        if (sizeof(long) == sizeof(int))
            return (int)(l - r);
        else if (l < r)
            return -1;
        else if (l > r)
            return 1;
        else
            return 0;
    }
    public int uintcmp(uint l, uint r) {
        return (int)l - (int)r;
    }

    public size_t hash_combine2(size_t h0, size_t h1) {
        return h0 ^ (h1 + 0x9e3779b9 + (h0 << 6) + (h0 >> 2));
    }
    public size_t hash_combine3(size_t h0, size_t h1, size_t h2) {
        return hash_combine2(h0, hash_combine2(h1, h2));
    }
}