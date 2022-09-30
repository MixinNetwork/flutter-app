#ifndef FLUTTER_PLUGIN_RAW_HWND_PLUGIN_H_
#define FLUTTER_PLUGIN_RAW_HWND_PLUGIN_H_

#include <windows.h>

#include <flutter_plugin_registrar.h>

#if defined(__cplusplus)
extern "C" {
#endif

void RawHwndPluginRegisterWithRegistrar(FlutterDesktopPluginRegistrarRef registrar, HWND handle);

#if defined(__cplusplus)
}  // extern "C"
#endif

#endif  // FLUTTER_PLUGIN_RAW_HWND_PLUGIN_H_