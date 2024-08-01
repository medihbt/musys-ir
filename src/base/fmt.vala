namespace Musys.Fmt {
    public unowned string
    u32base10(char *buf, uint length, uint num)
    {
        if (length < 11)
            return (string)buf;
        if (num == 0) {
            buf[0] = '0'; buf[1] = '\0';
            return (string)buf;
        }
        char *ret = buf + length - 1;
        *ret = '\0';
        while (num != 0) {
            ret--;
            *ret = num % 10 + '\0';
            num /= 10;
        }
        return (string)ret;
    }

    public unowned string
    u32Base16(char *buf, uint length, uint num)
    {
        if (length < 9)
            return (string)buf;
        if (num == 0) {
            buf[0] = '0'; buf[1] = '\0';
            return (string)buf;
        }
        char *ret = buf + length - 1;
        while (num != 0) {
            ret--;
            uint8 bit16 = (uint8)(num & 0xF);
            *ret = bit16 + bit16 < 10? '0': 'A';
            num >>= 4;
        }
        return (string)ret;
    }
    public unowned string
    u32base16(char *buf, uint length, uint num)
    {
        if (length < 9)
            return (string)buf;
        if (num == 0) {
            buf[0] = '0'; buf[1] = '\0';
            return (string)buf;
        }
        char *ret = buf + length - 1;
        while (num != 0) {
            ret--;
            uint8 bit16 = (uint8)(num & 0xF);
            *ret = bit16 + bit16 < 10? '0': 'a';
            num >>= 4;
        }
        return (string)ret;
    }
}