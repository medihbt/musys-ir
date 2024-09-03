namespace Musys {
    [CCode (simple_generics=true, cheader_filename="musys-base.h")]
    public extern unowned T static_cast<T>(void *u);

    [CCode (cheader_filename="musys-base.h")]
    public extern bool is_power_of_2(size_t value);

    [CCode (cheader_filename="musys-base.h")]
    public extern bool is_power_of_2_nonzero(size_t value);

    [CCode (cheader_filename="musys-base.h")]
    public extern size_t fill_to(size_t x, size_t mod);
}
