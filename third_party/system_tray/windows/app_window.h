#ifndef __AppWindow_H__
#define __AppWindow_H__

#include <Windows.h>

class AppWindow {
 public:
  bool initAppWindow(HWND window, HWND flutter_window);
  bool showAppWindow(bool visible);
  bool closeAppWindow();

 protected:
  void activeWindow();
  void refreshFlutterWindow();

 protected:
  HWND window_ = nullptr;
  HWND flutter_window_ = nullptr;
};

#endif  // __AppWindow_H__