#include "app_window.h"

bool AppWindow::initAppWindow(HWND window, HWND flutter_window) {
  window_ = window;
  flutter_window_ = flutter_window;
  return true;
}

bool AppWindow::showAppWindow(bool visible) {
  if (!IsWindow(window_)) {
    return false;
  }

  if (visible) {
    activeWindow();
    refreshFlutterWindow();
  } else {
    ShowWindow(window_, SW_HIDE);
  }
  return true;
}

bool AppWindow::closeAppWindow() {
  if (!IsWindow(window_)) {
    return false;
  }

  PostMessage(window_, WM_SYSCOMMAND, SC_CLOSE, 0);
  return true;
}

void AppWindow::activeWindow() {
  if (!IsWindow(window_)) {
    return;
  }

  if (!::IsWindowVisible(window_)) {
    ShowWindow(window_, SW_SHOW);
  }

  if (IsIconic(window_)) {
    SendMessage(window_, WM_SYSCOMMAND, SC_RESTORE | HTCAPTION, 0);
  }

  BringWindowToTop(window_);
  SetForegroundWindow(window_);
}

void AppWindow::refreshFlutterWindow() {
  if (!IsWindow(flutter_window_)) {
    return;
  }

  RECT rc = {};
  GetClientRect(flutter_window_, &rc);
  int width = rc.right - rc.left;
  int height = rc.bottom - rc.top;
  SetWindowPos(flutter_window_, 0, 0, 0, width + 1, height + 1,
               SWP_NOMOVE | SWP_NOACTIVATE);
  SetWindowPos(flutter_window_, 0, 0, 0, width, height,
               SWP_NOMOVE | SWP_NOACTIVATE);
}
