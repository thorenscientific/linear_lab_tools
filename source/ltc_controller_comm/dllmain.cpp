// dllmain.cpp : Defines the entry point for the DLL application.
#include "ftdi.hpp"
using namespace linear;

Ftdi ftdi;

#ifdef _WIN32
BOOL APIENTRY DllMain(HMODULE, DWORD, LPVOID) {
    return TRUE;
}
#endif

