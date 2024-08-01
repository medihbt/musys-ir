namespace Musys {
    [CCode (simple_generics=true, cheader_filename="musys-base.h")]
    public extern unowned T static_cast<T>(void *u);
}