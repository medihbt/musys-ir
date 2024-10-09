#pragma once

#include "musys-base.h"

#if !defined(VALA_EXTERN)
#if defined(_MSC_VER)
#define VALA_EXTERN __declspec(dllexport) extern
#elif __GNUC__ >= 4
#define VALA_EXTERN [[gnu::visibility("default")]] extern
#else
#define VALA_EXTERN extern
#endif
#endif

#ifdef __cplusplus
extern "C" {
#endif

VALA_EXTERN int musys_print_backtrace();

#ifdef __cplusplus
}
#endif