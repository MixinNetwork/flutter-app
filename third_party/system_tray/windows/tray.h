#ifndef __Tray_H__
#define __Tray_H__

#include <optional>
#include <string>

#include <windows.h>

#include <shellapi.h>

class SystemTray {
 public:
  class Delegate {
   public:
    virtual void OnSystemTrayEventCallback(const std::string& eventName) = 0;
  };

 public:
  SystemTray(Delegate* delegate);
  ~SystemTray();

  bool initSystemTray(HWND window,
                      const std::string* title,
                      const std::string* iconPath,
                      const std::string* toolTip);

  bool setSystemTrayInfo(const std::string* title,
                         const std::string* iconPath,
                         const std::string* toolTip);

  bool setContextMenu(HMENU context_menu);

  void popUpContextMenu();

  std::optional<LRESULT> HandleWindowProc(HWND hwnd,
                                          UINT message,
                                          WPARAM wparam,
                                          LPARAM lparam);

 protected:
  bool installTrayIcon(HWND window,
                       const std::string* title,
                       const std::string* iconPath,
                       const std::string* toolTip);
  bool removeTrayIcon();
  bool reinstallTrayIcon();
  void destroyIcon();
  void destroyMenu();

  std::optional<LRESULT> OnTrayIconCallback(UINT id,
                                            UINT notifyMsg,
                                            const POINT& pt);

  void ShowPopupMenu();

  const wchar_t* GetTrayWindowClass();
  void UnregisterWindowClass();

  static LRESULT CALLBACK TrayWndProc(HWND const window,
                                      UINT const message,
                                      WPARAM const wparam,
                                      LPARAM const lparam) noexcept;

  static SystemTray* GetThisFromHandle(HWND const window) noexcept;

  virtual LRESULT TrayMessageHandler(HWND window,
                                     UINT const message,
                                     WPARAM const wparam,
                                     LPARAM const lparam) noexcept;

  bool CreateTrayWindow();
  void DestoryTrayWindow();

 protected:
  HWND tray_window_ = nullptr;
  bool tray_class_registered_ = false;
  HWND window_ = nullptr;
  HMENU context_menu_ = nullptr;
  HICON icon_ = nullptr;

  UINT taskbar_created_message_ = RegisterWindowMessage(L"TaskbarCreated");
  UINT tray_notify_callback_message_ =
      RegisterWindowMessage(L"SystemTrayNotify");
  NOTIFYICONDATA nid_ = {sizeof(NOTIFYICONDATA)};
  bool tray_icon_installed_ = false;

  Delegate* delegate_ = nullptr;
};

#endif