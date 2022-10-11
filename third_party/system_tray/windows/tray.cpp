#include "tray.h"

#include <iostream>

#include <strsafe.h>
#include <windowsx.h>
#include <winuser.h>

namespace {
constexpr const wchar_t kTrayWindowClassName[] =
    L"FLUTTER_RUNNER_WIN32_WINDOW_TRAY";
}

const static char kSystemTrayEventLButtnUp[] = "leftMouseUp";
const static char kSystemTrayEventLButtnDown[] = "leftMouseDown";
const static char kSystemTrayEventLButtonDblClk[] = "leftMouseDblClk";
const static char kSystemTrayEventRButtnUp[] = "rightMouseUp";
const static char kSystemTrayEventRButtnDown[] = "rightMouseDown";

// Converts the given UTF-8 string to UTF-16.
static std::wstring Utf16FromUtf8(const std::string& utf8_string) {
  if (utf8_string.empty()) {
    return std::wstring();
  }
  int target_length =
      ::MultiByteToWideChar(CP_UTF8, MB_ERR_INVALID_CHARS, utf8_string.data(),
                            static_cast<int>(utf8_string.length()), nullptr, 0);
  if (target_length == 0) {
    return std::wstring();
  }
  std::wstring utf16_string;
  utf16_string.resize(target_length);
  int converted_length =
      ::MultiByteToWideChar(CP_UTF8, MB_ERR_INVALID_CHARS, utf8_string.data(),
                            static_cast<int>(utf8_string.length()),
                            utf16_string.data(), target_length);
  if (converted_length == 0) {
    return std::wstring();
  }
  return utf16_string;
}

SystemTray::SystemTray(Delegate* delegate) : delegate_(delegate) {}

SystemTray::~SystemTray() {
  removeTrayIcon();
  destroyIcon();
  destroyMenu();
  DestoryTrayWindow();
  UnregisterWindowClass();
}

bool SystemTray::initSystemTray(HWND window,
                                const std::string* title,
                                const std::string* iconPath,
                                const std::string* toolTip) {
  bool ret = false;

  do {
    if (tray_icon_installed_) {
      ret = true;
      break;
    }

    if (tray_window_ == nullptr) {
      if (!CreateTrayWindow()) {
        break;
      }
    }

    tray_icon_installed_ = installTrayIcon(window, title, iconPath, toolTip);

    ret = tray_icon_installed_;
  } while (false);

  return ret;
}

bool SystemTray::setSystemTrayInfo(const std::string* title,
                                   const std::string* iconPath,
                                   const std::string* toolTip) {
  bool ret = false;

  do {
    if (!IsWindow(window_)) {
      break;
    }

    if (!tray_icon_installed_) {
      break;
    }

    if (toolTip) {
      nid_.uFlags |= NIF_TIP;
      std::wstring toolTip_u = Utf16FromUtf8(*toolTip);
      StringCchCopy(nid_.szTip, _countof(nid_.szTip), toolTip_u.c_str());
    }

    if (iconPath) {
      destroyIcon();

      nid_.uFlags |= NIF_ICON;
      std::wstring iconPath_u = Utf16FromUtf8(*iconPath);
      icon_ =
          static_cast<HICON>(LoadImage(nullptr, iconPath_u.c_str(), IMAGE_ICON,
                                       0, 0, LR_LOADFROMFILE | LR_DEFAULTSIZE));
      nid_.hIcon = icon_;
    }

    if (!Shell_NotifyIcon(NIM_MODIFY, &nid_)) {
      break;
    }

    ret = true;
  } while (false);

  return ret;
}

bool SystemTray::setContextMenu(HMENU context_menu) {
  destroyMenu();
  context_menu_ = context_menu;
  return true;
}

void SystemTray::popUpContextMenu() {
  ShowPopupMenu();
}

bool SystemTray::installTrayIcon(HWND window,
                                 const std::string* title,
                                 const std::string* iconPath,
                                 const std::string* toolTip) {
  bool ret = false;

  do {
    destroyIcon();

    std::wstring title_u = title ? Utf16FromUtf8(*title) : L"";
    std::wstring iconPath_u = iconPath ? Utf16FromUtf8(*iconPath) : L"";
    std::wstring toolTip_u = toolTip ? Utf16FromUtf8(*toolTip) : L"";

    icon_ =
        static_cast<HICON>(LoadImage(nullptr, iconPath_u.c_str(), IMAGE_ICON, 0,
                                     0, LR_LOADFROMFILE | LR_DEFAULTSIZE));
    if (!icon_) {
      break;
    }

    window_ = window;

    nid_.uVersion = NOTIFYICON_VERSION_4;  // Windows Vista and later support
    nid_.hWnd = window_;
    nid_.hIcon = icon_;
    nid_.uCallbackMessage = tray_notify_callback_message_;
    StringCchCopy(nid_.szTip, _countof(nid_.szTip), toolTip_u.c_str());
    nid_.uFlags = NIF_MESSAGE | NIF_ICON | NIF_TIP;

    if (!Shell_NotifyIcon(NIM_ADD, &nid_)) {
      break;
    }

    ret = true;
  } while (false);

  return ret;
}

bool SystemTray::removeTrayIcon() {
  if (tray_icon_installed_) {
    return Shell_NotifyIcon(NIM_DELETE, &nid_);
  }
  return false;
}

bool SystemTray::reinstallTrayIcon() {
  if (tray_icon_installed_) {
    tray_icon_installed_ = Shell_NotifyIcon(NIM_ADD, &nid_);
    return tray_icon_installed_;
  }
  return false;
}

void SystemTray::destroyIcon() {
  if (icon_) {
    DestroyIcon(icon_);
    icon_ = nullptr;
  }
}

void SystemTray::destroyMenu() {
  if (context_menu_) {
    DestroyMenu(context_menu_);
    context_menu_ = nullptr;
  }
}

std::optional<LRESULT> SystemTray::HandleWindowProc(HWND hwnd,
                                                    UINT message,
                                                    WPARAM wparam,
                                                    LPARAM lparam) {
  if (message == taskbar_created_message_) {
    reinstallTrayIcon();
    return 0;
  } else if (message == tray_notify_callback_message_) {
    UINT id = HIWORD(lparam);
    UINT notifyMsg = LOWORD(lparam);
    POINT pt = {GET_X_LPARAM(wparam), GET_Y_LPARAM(wparam)};
    return OnTrayIconCallback(id, notifyMsg, pt);
  }
  return std::nullopt;
}

std::optional<LRESULT> SystemTray::OnTrayIconCallback(UINT id,
                                                      UINT notifyMsg,
                                                      const POINT& pt) {
  do {
    switch (notifyMsg) {
      case WM_LBUTTONDOWN: {
        if (delegate_) {
          delegate_->OnSystemTrayEventCallback(kSystemTrayEventLButtnDown);
        }
      } break;
      case WM_LBUTTONUP: {
        if (delegate_) {
          delegate_->OnSystemTrayEventCallback(kSystemTrayEventLButtnUp);
        }
      } break;
      case WM_LBUTTONDBLCLK: {
        if (delegate_) {
          delegate_->OnSystemTrayEventCallback(kSystemTrayEventLButtonDblClk);
        }
      } break;
      case WM_RBUTTONDOWN: {
        if (delegate_) {
          delegate_->OnSystemTrayEventCallback(kSystemTrayEventRButtnDown);
        }
      } break;
      case WM_RBUTTONUP: {
        if (delegate_) {
          delegate_->OnSystemTrayEventCallback(kSystemTrayEventRButtnUp);
        }
      } break;
        // default: {
        //   printf("OnTrayIconCallback id:%d, 0x%x, pt[%d,%d]\n", id,
        //   notifyMsg,
        //          pt.x, pt.y);
        // } break;
    }

  } while (false);
  return 0;
}

void SystemTray::ShowPopupMenu() {
  if (!context_menu_) {
    return;
  }

  POINT pt{};
  GetCursorPos(&pt);

  SetForegroundWindow(tray_window_);

  TrackPopupMenu(context_menu_, TPM_LEFTBUTTON, pt.x, pt.y, 0, window_,
                 nullptr);
  PostMessage(window_, WM_NULL, 0, 0);
}

const wchar_t* SystemTray::GetTrayWindowClass() {
  if (!tray_class_registered_) {
    WNDCLASS window_class{};
    window_class.hCursor = nullptr;
    window_class.lpszClassName = kTrayWindowClassName;
    window_class.style = CS_HREDRAW | CS_VREDRAW;
    window_class.cbClsExtra = 0;
    window_class.cbWndExtra = 0;
    window_class.hInstance = GetModuleHandle(nullptr);
    window_class.hIcon = nullptr;
    window_class.hbrBackground = 0;
    window_class.lpszMenuName = nullptr;
    window_class.lpfnWndProc = SystemTray::TrayWndProc;
    RegisterClass(&window_class);
    tray_class_registered_ = true;
  }

  return kTrayWindowClassName;
}

void SystemTray::UnregisterWindowClass() {
  UnregisterClass(kTrayWindowClassName, nullptr);
  tray_class_registered_ = false;
}

LRESULT CALLBACK SystemTray::TrayWndProc(HWND const window,
                                         UINT const message,
                                         WPARAM const wparam,
                                         LPARAM const lparam) noexcept {
  if (message == WM_NCCREATE) {
    auto window_struct = reinterpret_cast<CREATESTRUCT*>(lparam);
    SetWindowLongPtr(window, GWLP_USERDATA,
                     reinterpret_cast<LONG_PTR>(window_struct->lpCreateParams));
  } else if (SystemTray* that = GetThisFromHandle(window)) {
    return that->TrayMessageHandler(window, message, wparam, lparam);
  }

  return DefWindowProc(window, message, wparam, lparam);
}

SystemTray* SystemTray::GetThisFromHandle(HWND const window) noexcept {
  return reinterpret_cast<SystemTray*>(GetWindowLongPtr(window, GWLP_USERDATA));
}

LRESULT SystemTray::TrayMessageHandler(HWND window,
                                       UINT const message,
                                       WPARAM const wparam,
                                       LPARAM const lparam) noexcept {
  return DefWindowProc(window, message, wparam, lparam);
}

bool SystemTray::CreateTrayWindow() {
  HWND window =
      CreateWindow(GetTrayWindowClass(), nullptr, WS_OVERLAPPEDWINDOW, -1, -1,
                   0, 0, nullptr, nullptr, GetModuleHandle(nullptr), this);
  if (!window) {
    return false;
  }

  tray_window_ = window;
  return true;
}

void SystemTray::DestoryTrayWindow() {
  if (tray_window_) {
    DestroyWindow(tray_window_);
    tray_window_ = nullptr;
  }
}
