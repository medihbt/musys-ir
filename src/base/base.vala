namespace Musys {
    [CCode (simple_generics=true, cheader_filename="musys-base.h")]
    public extern unowned T static_cast<T>(void *u);

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
}
