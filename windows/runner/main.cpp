#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>

#include "flutter_window.h"
#include "utils.h"

#include <protocol_handler/protocol_handler_plugin.h>

class CSingleInstance {
 public:
  explicit CSingleInstance(LPCWSTR str_mutex_name) {
    h_mutex_ = CreateMutexW(nullptr, FALSE, str_mutex_name);
    dw_last_error_ = GetLastError();
  }

  ~CSingleInstance() {
    if (h_mutex_) {
      CloseHandle(h_mutex_);
      h_mutex_ = nullptr;
    }
  }

  [[nodiscard]] BOOL IsOtherInstanceRunning() const {
    return (ERROR_ALREADY_EXISTS == dw_last_error_);
  }

 protected:
  DWORD dw_last_error_;
  HANDLE h_mutex_;
};

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  HWND hwnd = ::FindWindow(L"FLUTTER_RUNNER_WIN32_WINDOW", L"Mixin");
  if (hwnd != NULL) {
    DispatchToProtocolHandler(hwnd);

    ::ShowWindow(hwnd, SW_NORMAL);
    ::SetForegroundWindow(hwnd);
    return EXIT_FAILURE;
  }
  // Attach to console when present (e.g., 'flutter run') or create a
  // new console when running with a debugger.
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  // Initialize COM, so that it is available for use in the library and/or
  // plugins.
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  // Create a single instance lock, to prevent multi process instance.
  CSingleInstance single_instance(L"Mixin_flutter_single_instance_identity_mutex_name");
  if (single_instance.IsOtherInstanceRunning()) {
    // If current has another app instance Running, we can find it and set it to foreground.
    HWND existingApp = FindWindow(nullptr, L"Mixin");
    if (existingApp) {
      SetForegroundWindow(existingApp);
    }
    return EXIT_FAILURE;
  }

  flutter::DartProject project(L"data");

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  FlutterWindow window(project);
  Win32Window::Point origin(10, 10);
  Win32Window::Size size(1280, 720);
  if (!window.CreateAndShow(L"Mixin", origin, size)) {
    return EXIT_FAILURE;
  }
  window.SetQuitOnClose(true);

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::CoUninitialize();
  return EXIT_SUCCESS;
}
