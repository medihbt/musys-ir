#pragma once
#include <stddef.h>
#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

/** @defgroup Musys
 * @{
 * @addtogroup Musys */
#define musys_static_cast(elem) ((gpointer)(elem))

/** @addtogroup Musys.Fmt */
static inline char const*
musys_fmt_u32base10(char *buf, unsigned length, unsigned number)
{
    if (length < 12) {
        *buf = '\0';
        return buf;
    }
    if (number == 0) {
        buf[0] = '0', buf[1] = '\0';
        return buf;
    }
    char *ret = buf + length - 1;
    *ret = 0;
    while (number != 0) {
        ret--;
        *ret = number % 10 + '0';
        number /= 10;
    }
    return ret;
}

/** @addtogroup Musys.Fmt */
static inline char const*
musys_fmt_u32base16(char *buf, unsigned length, unsigned number)
{
    static const char xdigits[16] = "0123456789abcdef";
    if (length < (sizeof(unsigned) * 2 + 1)) {
        *buf = '\0';
        return buf;
    }
    char *ret = buf + length - 1;
    *ret = 0;
    while (number != 0) {
        ret--;
        *ret = xdigits[number & 0xF];
        number >>= 4;
    }
    return ret;
}

/** @addtogroup Musys.Fmt */
static inline char const*
musys_fmt_u32Base16(char *buf, unsigned length, unsigned number)
{
    static const char xdigits[16] = "0123456789ABCDEF";
    if (length < (sizeof(unsigned) * 2 + 1)) {
        *buf = '\0';
        return buf;
    }
    char *ret = buf + length - 1;
    *ret = 0;
    while (number != 0) {
        ret--;
        *ret = xdigits[number & 0xF];
        number >>= 4;
    }
    return ret;
}

/** @addtogroup Musys */
static inline bool musys_is_power_of_2(size_t value) {
    return value && (value & value - 1);
}

/** @addtogroup Musys */
static inline size_t musys_fill_to(size_t x, size_t mod) {
    size_t xmod = x % mod;
    return xmod == 0? x: x - xmod + mod;
}

/** @} */

#ifdef __cplusplus
}
#endif
