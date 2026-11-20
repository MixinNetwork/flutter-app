#ifndef RUNNER_STORE_UPDATE_PLUGIN_H_
#define RUNNER_STORE_UPDATE_PLUGIN_H_

#include <windows.h>

#include <flutter_plugin_registrar.h>

// The "mixin_desktop/store_update" channel: updates of the Microsoft Store
// package. |hwnd| is the top-level window that Store dialogs belong to.
void StoreUpdatePluginRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar, HWND hwnd);

#endif  // RUNNER_STORE_UPDATE_PLUGIN_H_
