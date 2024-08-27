namespace Musys.Fmt {
    [CCode (cheader_filename="musys-base.h")]
    public extern unowned string u32base10([CCode(array_length = false)]char []buf, uint length, uint num);
    [CCode (cheader_filename="musys-base.h")]
    public extern unowned string u32Base16([CCode(array_length = false)]char []buf, uint length, uint num);
    [CCode (cheader_filename="musys-base.h")]
    public extern unowned string u32base16([CCode(array_length = false)]char []buf, uint length, uint num);
}
