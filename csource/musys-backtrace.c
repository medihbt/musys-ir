#include <stdio.h>
#include "musys-backtrace.h"

#ifdef _WIN32

#include <Windows.h>

int musys_print_backtrace()
{
    PVOID backtrace_buffer[32];
    DWORD backtrace_hash;
    USHORT nframes = CaptureStackBackTrace(0, 32, backtrace_buffer, &backtrace_hash);

    for (USHORT i = 0; i < nframes; i++) {
        fprintf(stderr, "Frame %hu address %p\n", i, backtrace_buffer[i]);
    }
    return 0;
}

#elif defined (__GNUC__) && defined (__GLIBC__)

#include <unistd.h>
#include <execinfo.h>

int musys_print_backtrace()
{
    void* trace_buffer[32] = {};
    int ret_nlayers = backtrace(trace_buffer, 32);
    backtrace_symbols_fd(trace_buffer, ret_nlayers, STDERR_FILENO);
    return ret_nlayers;
}

#else

int musys_print_backtrace() {
    fputs("This platform has not supported backtracing yet\n", stderr);
    return -1;
}

#endif
