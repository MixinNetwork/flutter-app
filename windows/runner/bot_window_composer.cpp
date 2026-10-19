// Lays out the app's browser windows like the mobile web view: no system
// title bar, the `... | x` capsule, and either a title row or, for immersive
// pages, a strip to drag the window. `...` asks Dart to show its menu in a
// Flutter view that shares the main engine.
//
// The header is painted by the browser window itself and reports HTCAPTION
// to drag. The capsule is a layered child window so it stays antialiased
// over the page. The menu's view is in a transparent popup window over the
// browser window's client area, as a child view cannot be: its clear pixels
// show the page, and Flutter's barrier takes the clicks outside the menu.

#include "bot_window_composer.h"

#include <windows.h>
#include <commctrl.h>
#include <dwmapi.h>
#include <shlwapi.h>
#include <uxtheme.h>
#include <wincrypt.h>
#include <windowsx.h>

#include <algorithm>
namespace Gdiplus {
using std::max;
using std::min;
}  // namespace Gdiplus
#include <gdiplus.h>

#include <desktop_webview_window/webview_window_composer.h>
#include <flutter/method_channel.h>
#include <flutter/standard_message_codec.h>
#include <flutter/standard_method_codec.h>
#include <flutter_windows.h>

#include <cmath>
#include <map>
#include <memory>
#include <optional>
#include <string>
#include <vector>

// Exported by flutter_windows.dll but missing from its installed headers;
// see shell/platform/windows/flutter_windows_internal.h (Flutter 3.47).
extern "C" {
struct BorrowedViewProperties {
  int width;
  int height;
};
// Unlike FlutterDesktopViewControllerCreate, does not take the engine over.
__declspec(dllimport) FlutterDesktopViewControllerRef
FlutterDesktopEngineCreateViewController(
    FlutterDesktopEngineRef engine, const BorrowedViewProperties* properties);
__declspec(dllimport) FlutterDesktopEngineRef
FlutterDesktopEngineForId(int64_t engine_id);
}

namespace bot_window_composer {
namespace {

using flutter::EncodableList;
using flutter::EncodableMap;
using flutter::EncodableValue;

constexpr UINT_PTR kSubclassId = 1;
constexpr int kDragHeight = 28;
constexpr int kTitleRowHeight = 48;
constexpr int kCapsuleWidth = 88;
constexpr int kCapsuleHeight = 32;
constexpr int kCapsuleMargin = 6;
constexpr int kLeadingSize = 24;
constexpr int kLeadingLeft = 12;
constexpr int kGap = 8;
// Before the menu reports its size.
constexpr wchar_t kCapsuleClass[] = L"MixinBotWindowCapsule";
constexpr wchar_t kPopupClass[] = L"MixinBotWindowPopup";

std::unique_ptr<flutter::MethodChannel<EncodableValue>> channel;

struct BotWindow {
  int64_t browser = 0;
  HWND window = nullptr;
  HWND webview = nullptr;
  HWND capsule = nullptr;
  HWND popup = nullptr;
  FlutterDesktopViewControllerRef popup_view = nullptr;
  bool immersive = false;
  bool follows_page_title = false;
  bool shows_icon = false;
  std::wstring title;
  COLORREF background = RGB(255, 255, 255);
  bool dark = false;
  std::unique_ptr<Gdiplus::Bitmap> icon;
  bool can_go_back = false;
  bool can_go_forward = false;
  bool back_hovered = false;
  bool back_pressed = false;
  bool tracking = false;
  int capsule_pressed = -1;  // 0: ..., 1: x
  bool popup_shown = false;
  bool dismiss_requested = false;
};

std::map<int64_t, std::unique_ptr<BotWindow>>& Windows() {
  static auto* windows = new std::map<int64_t, std::unique_ptr<BotWindow>>();
  return *windows;
}

BotWindow* Find(int64_t browser) {
  const auto found = Windows().find(browser);
  return found == Windows().end() ? nullptr : found->second.get();
}

// The capsule and popup keep their browser ID in GWLP_USERDATA.
BotWindow* FromHandle(HWND hwnd) {
  return Find(static_cast<int64_t>(GetWindowLongPtrW(hwnd, GWLP_USERDATA)));
}

const EncodableValue* Lookup(const EncodableMap& map, const char* key) {
  const auto found = map.find(EncodableValue(key));
  return found == map.end() ? nullptr : &found->second;
}

std::optional<int64_t> GetInt(const EncodableMap& map, const char* key) {
  const EncodableValue* value = Lookup(map, key);
  if (!value) return std::nullopt;
  if (const auto* number = std::get_if<int32_t>(value)) return *number;
  if (const auto* number = std::get_if<int64_t>(value)) return *number;
  return std::nullopt;
}

bool GetBool(const EncodableMap& map, const char* key) {
  const EncodableValue* value = Lookup(map, key);
  const auto* flag = value ? std::get_if<bool>(value) : nullptr;
  return flag && *flag;
}

std::wstring Wide(const std::string& utf8) {
  if (utf8.empty()) return {};
  const int length = MultiByteToWideChar(CP_UTF8, 0, utf8.data(),
                                         static_cast<int>(utf8.size()), nullptr, 0);
  std::wstring wide(length, L'\0');
  MultiByteToWideChar(CP_UTF8, 0, utf8.data(), static_cast<int>(utf8.size()),
                      wide.data(), length);
  return wide;
}

std::wstring GetString(const EncodableMap& map, const char* key) {
  const EncodableValue* value = Lookup(map, key);
  const auto* text = value ? std::get_if<std::string>(value) : nullptr;
  return text ? Wide(*text) : std::wstring();
}

// CreateConfiguration.composerArguments: base64 of a standard-codec map.
std::optional<EncodableMap> DecodeArguments(const char* arguments) {
  if (!arguments) return std::nullopt;
  DWORD size = 0;
  if (!CryptStringToBinaryA(arguments, 0, CRYPT_STRING_BASE64, nullptr, &size,
                            nullptr, nullptr)) {
    return std::nullopt;
  }
  std::vector<uint8_t> bytes(size);
  if (!CryptStringToBinaryA(arguments, 0, CRYPT_STRING_BASE64, bytes.data(),
                            &size, nullptr, nullptr)) {
    return std::nullopt;
  }
  auto value = flutter::StandardMessageCodec::GetInstance().DecodeMessage(
      bytes.data(), size);
  const auto* map = value ? std::get_if<EncodableMap>(value.get()) : nullptr;
  if (!map) return std::nullopt;
  return *map;
}

int Scaled(HWND window, int logical) {
  return MulDiv(logical, static_cast<int>(GetDpiForWindow(window)), 96);
}

float ScaleOf(HWND window) {
  return static_cast<float>(GetDpiForWindow(window)) / 96.0f;
}

int HeaderHeight(const BotWindow& bot) {
  return Scaled(bot.window, bot.immersive ? kDragHeight : kTitleRowHeight);
}

// Over the page 6 below the strip, or centred in the title row.
RECT CapsuleRect(const BotWindow& bot) {
  RECT client;
  GetClientRect(bot.window, &client);
  const int right = client.right - Scaled(bot.window, kCapsuleMargin);
  const int top = Scaled(bot.window, bot.immersive
                                         ? kDragHeight + 6
                                         : (kTitleRowHeight - kCapsuleHeight) / 2);
  return {right - Scaled(bot.window, kCapsuleWidth), top, right,
          top + Scaled(bot.window, kCapsuleHeight)};
}

// The 24 x 24 slot before the title: the bot's icon, which turns into `<`
// while the page can go back. Pages without an icon show it only for `<`.
// Immersive pages have no row and offer going back themselves.
bool LeadingShown(const BotWindow& bot) {
  return !bot.immersive && (bot.shows_icon || bot.can_go_back);
}

RECT LeadingRect(const BotWindow& bot) {
  const int size = Scaled(bot.window, kLeadingSize);
  const int left = Scaled(bot.window, kLeadingLeft);
  const int top = (Scaled(bot.window, kTitleRowHeight) - size) / 2;
  return {left, top, left + size, top + size};
}

bool InBack(const BotWindow& bot, POINT point) {
  const RECT rect = LeadingRect(bot);
  return LeadingShown(bot) && bot.can_go_back && PtInRect(&rect, point);
}

void InvalidateHeader(const BotWindow& bot) {
  RECT rect;
  GetClientRect(bot.window, &rect);
  rect.bottom = HeaderHeight(bot);
  InvalidateRect(bot.window, &rect, FALSE);
}

Gdiplus::Color Argb(uint32_t argb) {
  return Gdiplus::Color(static_cast<Gdiplus::ARGB>(argb));
}

std::unique_ptr<Gdiplus::Bitmap> DecodeIcon(const std::vector<uint8_t>& png) {
  IStream* stream = SHCreateMemStream(png.data(), static_cast<UINT>(png.size()));
  if (!stream) return nullptr;
  std::unique_ptr<Gdiplus::Bitmap> icon;
  {
    // Drawn into a copy: the decoded bitmap needs its stream.
    Gdiplus::Bitmap decoded(stream);
    if (decoded.GetLastStatus() == Gdiplus::Ok) {
      icon = std::make_unique<Gdiplus::Bitmap>(
          decoded.GetWidth(), decoded.GetHeight(), PixelFormat32bppPARGB);
      Gdiplus::Graphics graphics(icon.get());
      graphics.DrawImage(&decoded, 0, 0, decoded.GetWidth(), decoded.GetHeight());
    }
  }
  stream->Release();
  return icon;
}

void PaintLeading(const BotWindow& bot, HDC dc) {
  Gdiplus::Graphics graphics(dc);
  graphics.SetSmoothingMode(Gdiplus::SmoothingModeAntiAlias);
  graphics.SetPixelOffsetMode(Gdiplus::PixelOffsetModeHighQuality);
  graphics.SetInterpolationMode(Gdiplus::InterpolationModeHighQualityBicubic);
  const RECT slot = LeadingRect(bot);
  const Gdiplus::RectF rect(static_cast<float>(slot.left),
                            static_cast<float>(slot.top),
                            static_cast<float>(slot.right - slot.left),
                            static_cast<float>(slot.bottom - slot.top));
  const Gdiplus::SolidBrush fill(Argb(bot.dark ? 0x26FFFFFF : 0x14000000));
  if (bot.can_go_back) {
    if (bot.back_hovered) graphics.FillEllipse(&fill, rect);
    const float unit = rect.Width / kLeadingSize;
    Gdiplus::Pen pen(Argb(bot.dark ? 0xFFFFFFFF : 0xFF000000), 2 * unit);
    pen.SetStartCap(Gdiplus::LineCapRound);
    pen.SetEndCap(Gdiplus::LineCapRound);
    pen.SetLineJoin(Gdiplus::LineJoinRound);
    const Gdiplus::PointF chevron[] = {
        {rect.X + 14 * unit, rect.Y + 6 * unit},
        {rect.X + 8 * unit, rect.Y + 12 * unit},
        {rect.X + 14 * unit, rect.Y + 18 * unit},
    };
    graphics.DrawLines(&pen, chevron, 3);
  } else if (bot.icon) {
    Gdiplus::TextureBrush brush(bot.icon.get(), Gdiplus::WrapModeClamp);
    brush.TranslateTransform(rect.X, rect.Y);
    brush.ScaleTransform(rect.Width / bot.icon->GetWidth(),
                         rect.Height / bot.icon->GetHeight());
    graphics.FillEllipse(&brush, rect);
  } else {
    // Holds the icon's place until it loads, or if it never does.
    graphics.FillEllipse(&fill, rect);
  }
}

void Paint(const BotWindow& bot) {
  PAINTSTRUCT paint;
  HDC dc = BeginPaint(bot.window, &paint);
  BP_PAINTPARAMS params{sizeof(params)};
  HDC buffer_dc = nullptr;
  HPAINTBUFFER buffer = BeginBufferedPaint(dc, &paint.rcPaint, BPBF_TOPDOWNDIB,
                                           &params, &buffer_dc);
  if (!buffer) {
    EndPaint(bot.window, &paint);
    return;
  }
  // The header, and the rest until the page covers it.
  RECT client;
  GetClientRect(bot.window, &client);
  HBRUSH background = CreateSolidBrush(bot.background);
  FillRect(buffer_dc, &client, background);
  DeleteObject(background);
  if (!bot.immersive) {
    const RECT capsule = CapsuleRect(bot);
    RECT text{LeadingShown(bot) ? LeadingRect(bot).right + Scaled(bot.window, kGap)
                                : Scaled(bot.window, kLeadingLeft),
              0, capsule.left - Scaled(bot.window, kGap),
              Scaled(bot.window, kTitleRowHeight)};
    HFONT font = CreateFontW(-Scaled(bot.window, 16), 0, 0, 0, FW_SEMIBOLD,
                             FALSE, FALSE, FALSE, DEFAULT_CHARSET,
                             OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS,
                             CLEARTYPE_QUALITY, DEFAULT_PITCH, L"Segoe UI");
    HGDIOBJ previous = SelectObject(buffer_dc, font);
    SetBkMode(buffer_dc, TRANSPARENT);
    SetTextColor(buffer_dc, bot.dark ? RGB(255, 255, 255) : RGB(0, 0, 0));
    // A long title truncates; the window keeps its width.
    DrawTextW(buffer_dc, bot.title.c_str(), -1, &text,
              DT_LEFT | DT_VCENTER | DT_SINGLELINE | DT_END_ELLIPSIS | DT_NOPREFIX);
    SelectObject(buffer_dc, previous);
    DeleteObject(font);
    if (LeadingShown(bot)) PaintLeading(bot, buffer_dc);
  }
  // GDI leaves alpha clear, which DWM's frame would show through.
  BufferedPaintSetAlpha(buffer, nullptr, 255);
  EndBufferedPaint(buffer, TRUE);
  EndPaint(bot.window, &paint);
}

void AddRoundedRect(Gdiplus::GraphicsPath& path, const Gdiplus::RectF& rect,
                    float radius) {
  const float diameter = radius * 2;
  path.AddArc(rect.X, rect.Y, diameter, diameter, 180, 90);
  path.AddArc(rect.GetRight() - diameter, rect.Y, diameter, diameter, 270, 90);
  path.AddArc(rect.GetRight() - diameter, rect.GetBottom() - diameter, diameter,
              diameter, 0, 90);
  path.AddArc(rect.X, rect.GetBottom() - diameter, diameter, diameter, 90, 90);
  path.CloseFigure();
}

// `... | x`, styled like Android's WebControlView. In logical pixels.
void DrawCapsule(Gdiplus::Graphics& graphics, const BotWindow& bot) {
  const bool dark = bot.dark;
  const float width = kCapsuleWidth;
  const float height = kCapsuleHeight;
  const float half = width / 2;
  Gdiplus::GraphicsPath shape;
  AddRoundedRect(shape, Gdiplus::RectF(0.5f, 0.5f, width - 1, height - 1),
                 (height - 1) / 2);
  const Gdiplus::SolidBrush fill(Argb(dark ? 0xFF24262A : 0xC7F9F9F9));
  graphics.FillPath(&fill, &shape);
  const Gdiplus::Pen stroke(Argb(dark ? 0x0FFFFFFF : 0x0F000000), 1);
  graphics.DrawPath(&stroke, &shape);

  if (bot.capsule_pressed >= 0) {
    graphics.SetClip(Gdiplus::RectF(bot.capsule_pressed == 0 ? 0 : half, 0,
                                    half, height));
    const Gdiplus::SolidBrush pressed(Argb(dark ? 0x1FFFFFFF : 0x14000000));
    graphics.FillPath(&pressed, &shape);
    graphics.ResetClip();
  }

  const Gdiplus::SolidBrush divider(Argb(dark ? 0x33FFFFFF : 0x1F000000));
  graphics.FillRectangle(&divider, Gdiplus::RectF(half - 0.5f, 8, 1, height - 16));

  const Gdiplus::Color icon = Argb(dark ? 0xFFFFFFFF : 0xFF000000);
  const Gdiplus::SolidBrush dots(icon);
  for (const float dx : {-6.0f, 0.0f, 6.0f}) {
    graphics.FillEllipse(&dots, half / 2 + dx - 1.75f, height / 2 - 1.75f, 3.5f,
                         3.5f);
  }
  Gdiplus::Pen cross(icon, 1.6f);
  cross.SetStartCap(Gdiplus::LineCapRound);
  cross.SetEndCap(Gdiplus::LineCapRound);
  const float x = half * 1.5f;
  const float y = height / 2;
  graphics.DrawLine(&cross, x - 5, y - 5, x + 5, y + 5);
  graphics.DrawLine(&cross, x + 5, y - 5, x - 5, y + 5);
}

void RenderCapsule(const BotWindow& bot) {
  if (!bot.capsule) return;
  const int width = Scaled(bot.window, kCapsuleWidth);
  const int height = Scaled(bot.window, kCapsuleHeight);
  BITMAPINFO info{};
  info.bmiHeader = {sizeof(BITMAPINFOHEADER), width, -height, 1, 32, BI_RGB};
  void* bits = nullptr;
  HDC screen = GetDC(nullptr);
  HDC dc = CreateCompatibleDC(screen);
  HBITMAP bitmap = CreateDIBSection(screen, &info, DIB_RGB_COLORS, &bits, nullptr, 0);
  if (bitmap) {
    HGDIOBJ previous = SelectObject(dc, bitmap);
    {
      // Premultiplied, as UpdateLayeredWindow takes it.
      Gdiplus::Bitmap canvas(width, height, width * 4, PixelFormat32bppPARGB,
                             static_cast<BYTE*>(bits));
      Gdiplus::Graphics graphics(&canvas);
      graphics.SetSmoothingMode(Gdiplus::SmoothingModeAntiAlias);
      graphics.SetPixelOffsetMode(Gdiplus::PixelOffsetModeHighQuality);
      graphics.Clear(Gdiplus::Color(0, 0, 0, 0));
      const float scale = ScaleOf(bot.window);
      graphics.ScaleTransform(scale, scale);
      DrawCapsule(graphics, bot);
    }
    POINT origin{0, 0};
    SIZE size{width, height};
    BLENDFUNCTION blend{AC_SRC_OVER, 0, 255, AC_SRC_ALPHA};
    UpdateLayeredWindow(bot.capsule, screen, nullptr, &size, dc, &origin, 0,
                        &blend, ULW_ALPHA);
    SelectObject(dc, previous);
    DeleteObject(bitmap);
  }
  DeleteDC(dc);
  ReleaseDC(nullptr, screen);
}

EncodableValue BrowserArguments(int64_t browser) {
  return EncodableValue(EncodableMap{
      {EncodableValue("browserId"), EncodableValue(browser)},
  });
}

void Invoke(const char* method, int64_t browser) {
  if (channel) {
    channel->InvokeMethod(method, std::make_unique<EncodableValue>(
                                      BrowserArguments(browser)));
  }
}

// Dart hides the menu, then the popup through hidePopup.
void RequestDismiss(BotWindow& bot) {
  if (!bot.popup_shown || bot.dismiss_requested) return;
  bot.dismiss_requested = true;
  Invoke("onDismissPopup", bot.browser);
}

HWND ViewWindow(FlutterDesktopViewControllerRef controller) {
  return FlutterDesktopViewGetHWND(FlutterDesktopViewControllerGetView(controller));
}

LRESULT CALLBACK CapsuleProc(HWND hwnd, UINT message, WPARAM wparam,
                             LPARAM lparam) {
  BotWindow* bot = FromHandle(hwnd);
  if (!bot) return DefWindowProcW(hwnd, message, wparam, lparam);
  const POINT point{GET_X_LPARAM(lparam), GET_Y_LPARAM(lparam)};
  RECT client;
  GetClientRect(hwnd, &client);
  const int half = point.x < client.right / 2 ? 0 : 1;
  switch (message) {
    case WM_LBUTTONDOWN:
      bot->capsule_pressed = half;
      SetCapture(hwnd);
      RenderCapsule(*bot);
      return 0;
    case WM_LBUTTONUP: {
      const int pressed = bot->capsule_pressed;
      if (pressed < 0) return 0;
      bot->capsule_pressed = -1;
      ReleaseCapture();
      RenderCapsule(*bot);
      if (!PtInRect(&client, point) || half != pressed) return 0;
      // Last: closing destroys this window.
      if (pressed == 0) {
        Invoke("onMoreTapped", bot->browser);
      } else {
        dww_browser_close(bot->browser);
      }
      return 0;
    }
    case WM_CAPTURECHANGED:
      if (bot->capsule_pressed >= 0) {
        bot->capsule_pressed = -1;
        RenderCapsule(*bot);
      }
      return 0;
  }
  return DefWindowProcW(hwnd, message, wparam, lparam);
}

LRESULT CALLBACK PopupProc(HWND hwnd, UINT message, WPARAM wparam,
                           LPARAM lparam) {
  BotWindow* bot = FromHandle(hwnd);
  if (!bot) return DefWindowProcW(hwnd, message, wparam, lparam);
  // Not forwarded to FlutterDesktopViewControllerHandleTopLevelWindowProc:
  // plugins registered there, like window_manager, take any HWND for the
  // main window's.
  switch (message) {
    case WM_ACTIVATE:
      // Like a menu: anything else taking focus closes it.
      if (LOWORD(wparam) == WA_INACTIVE) {
        RequestDismiss(*bot);
      } else if (bot->popup_view) {
        SetFocus(ViewWindow(bot->popup_view));
      }
      return 0;
    case WM_SIZE:
      if (bot->popup_view) {
        MoveWindow(ViewWindow(bot->popup_view), 0, 0, LOWORD(lparam),
                   HIWORD(lparam), TRUE);
      }
      return 0;
    case WM_CLOSE:
      RequestDismiss(*bot);
      return 0;
  }
  return DefWindowProcW(hwnd, message, wparam, lparam);
}

// Alt+Left and Alt+Right, and the mouse's back and forward buttons, navigate
// in every layout. WebView2 takes them over the page itself; these reach the
// header, and app commands WebView2 leaves to its parents.
void Navigate(const BotWindow& bot, bool forward) {
  if (bot.popup_shown) return;
  if (forward) {
    if (bot.can_go_forward) dww_browser_go_forward(bot.browser);
  } else if (bot.can_go_back) {
    dww_browser_go_back(bot.browser);
  }
}

LRESULT CALLBACK BotWindowProc(HWND hwnd, UINT message, WPARAM wparam,
                               LPARAM lparam, UINT_PTR, DWORD_PTR data) {
  BotWindow* bot = Find(static_cast<int64_t>(data));
  if (!bot) return DefSubclassProc(hwnd, message, wparam, lparam);
  switch (message) {
    case WM_NCCALCSIZE:
      // The whole window is client area; DWM keeps the shadow and corners.
      if (wparam) return 0;
      break;
    case WM_NCHITTEST: {
      POINT point{GET_X_LPARAM(lparam), GET_Y_LPARAM(lparam)};
      ScreenToClient(hwnd, &point);
      // No resize borders: the page is laid out for a phone.
      if (point.y >= HeaderHeight(*bot) || InBack(*bot, point)) return HTCLIENT;
      return HTCAPTION;
    }
    case WM_NCLBUTTONDBLCLK:
      // Double-clicks on the header do nothing.
      if (wparam == HTCAPTION) return 0;
      break;
    case WM_XBUTTONUP:
    case WM_NCXBUTTONUP:
      Navigate(*bot, GET_XBUTTON_WPARAM(wparam) == XBUTTON2);
      return TRUE;
    case WM_APPCOMMAND: {
      const int command = GET_APPCOMMAND_LPARAM(lparam);
      if (command != APPCOMMAND_BROWSER_BACKWARD &&
          command != APPCOMMAND_BROWSER_FORWARD) {
        break;
      }
      Navigate(*bot, command == APPCOMMAND_BROWSER_FORWARD);
      return TRUE;
    }
    case WM_SYSKEYDOWN:
      // Bit 29: Alt is down.
      if ((wparam == VK_LEFT || wparam == VK_RIGHT) && (lparam & (1 << 29))) {
        Navigate(*bot, wparam == VK_RIGHT);
        return 0;
      }
      break;
    case WM_ERASEBKGND:
      return 1;
    case WM_PAINT:
      Paint(*bot);
      return 0;
    case WM_MOUSEMOVE: {
      if (!bot->tracking) {
        TRACKMOUSEEVENT track{sizeof(track), TME_LEAVE, hwnd};
        bot->tracking = TrackMouseEvent(&track);
      }
      const bool hovered = InBack(*bot, {GET_X_LPARAM(lparam), GET_Y_LPARAM(lparam)});
      if (hovered != bot->back_hovered) {
        bot->back_hovered = hovered;
        InvalidateHeader(*bot);
      }
      return 0;
    }
    case WM_MOUSELEAVE:
      bot->tracking = false;
      if (bot->back_hovered) {
        bot->back_hovered = false;
        InvalidateHeader(*bot);
      }
      return 0;
    case WM_LBUTTONDOWN:
      if (InBack(*bot, {GET_X_LPARAM(lparam), GET_Y_LPARAM(lparam)})) {
        bot->back_pressed = true;
        SetCapture(hwnd);
      }
      return 0;
    case WM_LBUTTONUP:
      if (bot->back_pressed) {
        bot->back_pressed = false;
        ReleaseCapture();
        if (InBack(*bot, {GET_X_LPARAM(lparam), GET_Y_LPARAM(lparam)})) {
          dww_browser_go_back(bot->browser);
        }
      }
      return 0;
  }
  return DefSubclassProc(hwnd, message, wparam, lparam);
}

void RegisterWindowClass(const wchar_t* name, WNDPROC proc, UINT style) {
  WNDCLASSW window_class{};
  window_class.style = style;
  window_class.lpfnWndProc = proc;
  window_class.hInstance = GetModuleHandle(nullptr);
  window_class.hCursor = LoadCursor(nullptr, IDC_ARROW);
  window_class.lpszClassName = name;
  RegisterClassW(&window_class);
}

HWND CreateChild(const wchar_t* class_name, DWORD style, HWND parent,
                 int64_t browser) {
  HWND child = CreateWindowExW(WS_EX_LAYERED, class_name, L"", WS_CHILD | style,
                               0, 0, 1, 1, parent, nullptr,
                               GetModuleHandle(nullptr), nullptr);
  SetWindowLongPtrW(child, GWLP_USERDATA, static_cast<LONG_PTR>(browser));
  return child;
}

void SetChrome(BotWindow& bot, const EncodableMap& arguments) {
  if (const auto color = GetInt(arguments, "backgroundColor")) {
    const auto argb = static_cast<uint32_t>(*color);
    bot.background = RGB((argb >> 16) & 0xFF, (argb >> 8) & 0xFF, argb & 0xFF);
  }
  if (Lookup(arguments, "dark")) bot.dark = GetBool(arguments, "dark");
  const EncodableValue* icon = Lookup(arguments, "icon");
  if (const auto* bytes = icon ? std::get_if<std::vector<uint8_t>>(icon) : nullptr) {
    if (auto decoded = DecodeIcon(*bytes)) bot.icon = std::move(decoded);
  }
}

DWWComposeResult Compose(void*, const DWWComposeRequest* request) {
  const auto arguments = DecodeArguments(request->arguments);
  if (!arguments) return DWW_COMPOSE_DEFAULT;
  auto owned = std::make_unique<BotWindow>();
  BotWindow& bot = *owned;
  bot.browser = request->browser;
  bot.window = static_cast<HWND>(request->window);
  bot.webview = static_cast<HWND>(request->webview_view);
  bot.immersive = GetBool(*arguments, "immersive");
  bot.follows_page_title = GetBool(*arguments, "followPageTitle");
  bot.shows_icon = GetBool(*arguments, "showIcon");
  bot.title = GetString(*arguments, "title");
  SetChrome(bot, *arguments);
  SetWindowTextW(bot.window, bot.title.c_str());

  // Fixed size, no maximize.
  auto style = GetWindowLongPtrW(bot.window, GWL_STYLE);
  SetWindowLongPtrW(bot.window, GWL_STYLE, style & ~(WS_THICKFRAME | WS_MAXIMIZEBOX));
  const DWORD round = 2;  // DWMWCP_ROUND
  DwmSetWindowAttribute(bot.window, static_cast<DWMWINDOWATTRIBUTE>(33), &round,
                        sizeof(round));
  // Keeps DWM's shadow without a frame.
  const MARGINS margins{0, 0, 1, 0};
  DwmExtendFrameIntoClientArea(bot.window, &margins);

  bot.capsule = CreateChild(kCapsuleClass, WS_VISIBLE, bot.window, bot.browser);
  // New children go below their siblings; immersive pages put it over the
  // WebView.
  SetWindowPos(bot.capsule, HWND_TOP, 0, 0, 0, 0,
               SWP_NOMOVE | SWP_NOSIZE | SWP_NOACTIVATE);

  Windows()[bot.browser] = std::move(owned);
  SetWindowSubclass(bot.window, BotWindowProc, kSubclassId,
                    static_cast<DWORD_PTR>(bot.browser));
  SetWindowPos(bot.window, nullptr, 0, 0, 0, 0,
               SWP_NOMOVE | SWP_NOSIZE | SWP_NOZORDER | SWP_NOACTIVATE |
                   SWP_FRAMECHANGED);
  return DWW_COMPOSE_HANDLED;
}

void Layout(void*, int64_t browser, int32_t width, int32_t height) {
  BotWindow* bot = Find(browser);
  if (!bot) return;
  const int top = HeaderHeight(*bot);
  MoveWindow(bot->webview, 0, top, width, (std::max)(0, height - top), TRUE);
  const RECT capsule = CapsuleRect(*bot);
  SetWindowPos(bot->capsule, nullptr, capsule.left, capsule.top,
               capsule.right - capsule.left, capsule.bottom - capsule.top,
               SWP_NOZORDER | SWP_NOACTIVATE);
  RenderCapsule(*bot);
  InvalidateHeader(*bot);
}

void NavigationChanged(void*, const DWWNavigationState* state) {
  BotWindow* bot = Find(state->browser);
  if (!bot) return;
  bot->can_go_back = state->can_go_back != 0;
  bot->can_go_forward = state->can_go_forward != 0;
  if (!bot->can_go_back) bot->back_hovered = false;
  if (bot->follows_page_title) {
    bot->title = state->title ? Wide(state->title) : std::wstring();
    SetWindowTextW(bot->window, bot->title.c_str());
  }
  InvalidateHeader(*bot);
}

void Closing(void*, int64_t browser) {
  const auto found = Windows().find(browser);
  if (found == Windows().end()) return;
  BotWindow& bot = *found->second;
  RemoveWindowSubclass(bot.window, BotWindowProc, kSubclassId);
  // Removes the view from the engine.
  if (bot.popup_view) FlutterDesktopViewControllerDestroy(bot.popup_view);
  for (HWND window : {bot.popup, bot.capsule}) {
    if (window) DestroyWindow(window);
  }
  Windows().erase(found);
}

// Lets the view's alpha through, as window_manager does for a transparent
// background.
void MakeTransparent(HWND window) {
  struct AccentPolicy {
    int state;
    int flags;
    int color;
    int animation;
  };
  struct CompositionData {
    int attribute;
    PVOID data;
    ULONG size;
  };
  using SetComposition = BOOL(WINAPI*)(HWND, CompositionData*);
  const auto set_composition = reinterpret_cast<SetComposition>(GetProcAddress(
      GetModuleHandleW(L"user32.dll"), "SetWindowCompositionAttribute"));
  if (!set_composition) return;
  AccentPolicy policy{2, 2, 0, 0};  // ACCENT_ENABLE_TRANSPARENTGRADIENT
  CompositionData data{19, &policy, sizeof(policy)};  // WCA_ACCENT_POLICY
  set_composition(window, &data);
}

// The view is created on first use, then hidden and reused until the window
// closes.
std::optional<EncodableValue> ShowPopup(BotWindow& bot, int64_t engine_id) {
  RECT client;
  GetClientRect(bot.window, &client);
  if (!bot.popup_view) {
    FlutterDesktopEngineRef engine = FlutterDesktopEngineForId(engine_id);
    if (!engine) return std::nullopt;
    const BorrowedViewProperties properties{client.right, client.bottom};
    bot.popup = CreateWindowExW(
        WS_EX_TOOLWINDOW, kPopupClass, L"", WS_POPUP | WS_CLIPCHILDREN, 0, 0,
        properties.width, properties.height, bot.window, nullptr,
        GetModuleHandle(nullptr), nullptr);
    SetWindowLongPtrW(bot.popup, GWLP_USERDATA, static_cast<LONG_PTR>(bot.browser));
    // Covers the client area; the browser window has the round corners.
    const DWORD square = 1;  // DWMWCP_DONOTROUND
    DwmSetWindowAttribute(bot.popup, static_cast<DWMWINDOWATTRIBUTE>(33), &square,
                          sizeof(square));
    const MARGINS glass{-1, -1, -1, -1};
    DwmExtendFrameIntoClientArea(bot.popup, &glass);
    MakeTransparent(bot.popup);
    bot.popup_view = FlutterDesktopEngineCreateViewController(engine, &properties);
    if (!bot.popup_view) {
      DestroyWindow(bot.popup);
      bot.popup = nullptr;
      return std::nullopt;
    }
    HWND view = ViewWindow(bot.popup_view);
    SetParent(view, bot.popup);
    MoveWindow(view, 0, 0, properties.width, properties.height, FALSE);
    ShowWindow(view, SW_SHOW);
  }
  bot.popup_shown = true;
  bot.dismiss_requested = false;
  POINT origin{0, 0};
  ClientToScreen(bot.window, &origin);
  SetWindowPos(bot.popup, HWND_TOP, origin.x, origin.y, client.right,
               client.bottom, SWP_SHOWWINDOW);
  SetForegroundWindow(bot.popup);
  FlutterDesktopViewControllerForceRedraw(bot.popup_view);
  const float scale = ScaleOf(bot.window);
  const RECT capsule = CapsuleRect(bot);
  return EncodableValue(EncodableMap{
      {EncodableValue("viewId"),
       EncodableValue(static_cast<int64_t>(
           FlutterDesktopViewControllerGetViewId(bot.popup_view)))},
      {EncodableValue("anchor"),
       EncodableValue(EncodableList{
           EncodableValue(capsule.left / scale),
           EncodableValue(capsule.top / scale),
           EncodableValue((capsule.right - capsule.left) / scale),
           EncodableValue((capsule.bottom - capsule.top) / scale),
       })},
  });
}

void HidePopup(BotWindow& bot) {
  bot.popup_shown = false;
  if (!bot.popup) return;
  const bool active = GetForegroundWindow() == bot.popup;
  ShowWindow(bot.popup, SW_HIDE);
  if (active) SetForegroundWindow(bot.window);
}

void Focus(const BotWindow& bot) {
  if (IsIconic(bot.window)) ShowWindow(bot.window, SW_RESTORE);
  SetForegroundWindow(bot.window);
}

#ifndef NDEBUG
// For integration tests; the same on every platform. Points are top-left
// based, in logical window content coordinates.

// What takes a click at a client point, in physical pixels.
const char* RoleAt(const BotWindow& bot, POINT point) {
  if (bot.popup && IsWindowVisible(bot.popup)) return "popup";
  const RECT capsule = CapsuleRect(bot);
  if (PtInRect(&capsule, point)) return "capsule";
  if (InBack(bot, point)) return "leading";
  return point.y < HeaderHeight(bot) ? "header" : "page";
}

POINT DebugPoint(const BotWindow& bot, const EncodableValue& value) {
  const auto* pair = std::get_if<EncodableList>(&value);
  const float scale = ScaleOf(bot.window);
  auto coordinate = [&](size_t i) {
    const auto* number =
        pair && pair->size() > i ? std::get_if<double>(&(*pair)[i]) : nullptr;
    return number ? static_cast<LONG>(std::lround(*number * scale)) : 0;
  };
  return {coordinate(0), coordinate(1)};
}

int64_t ArgbOf(COLORREF color) {
  return 0xFF000000 | (GetRValue(color) << 16) | (GetGValue(color) << 8) |
         GetBValue(color);
}

// DWM's copy of the window, children included, even while covered.
std::vector<uint32_t> Capture(HWND window, int width, int height) {
  std::vector<uint32_t> pixels(static_cast<size_t>(width) * height);
  HDC screen = GetDC(nullptr);
  HDC dc = CreateCompatibleDC(screen);
  HBITMAP bitmap = CreateCompatibleBitmap(screen, width, height);
  HGDIOBJ previous = SelectObject(dc, bitmap);
  PrintWindow(window, dc, PW_CLIENTONLY | PW_RENDERFULLCONTENT);
  SelectObject(dc, previous);
  BITMAPINFO info{};
  info.bmiHeader = {sizeof(BITMAPINFOHEADER), width, -height, 1, 32, BI_RGB};
  GetDIBits(dc, bitmap, 0, height, pixels.data(), &info, DIB_RGB_COLORS);
  DeleteObject(bitmap);
  DeleteDC(dc);
  ReleaseDC(nullptr, screen);
  return pixels;
}

EncodableValue DebugProbe(const BotWindow& bot, const EncodableMap& arguments) {
  RECT client;
  GetClientRect(bot.window, &client);
  const auto pixels = Capture(bot.window, client.right, client.bottom);
  EncodableList probes;
  const EncodableValue* points = Lookup(arguments, "points");
  if (const auto* list = points ? std::get_if<EncodableList>(points) : nullptr) {
    for (const auto& value : *list) {
      const POINT point = DebugPoint(bot, value);
      int64_t color = 0;
      if (PtInRect(&client, point)) {
        color = 0xFF000000 |
                (pixels[static_cast<size_t>(point.y) * client.right + point.x] &
                 0xFFFFFF);
      }
      probes.push_back(EncodableValue(EncodableMap{
          {EncodableValue("hit"), EncodableValue(RoleAt(bot, point))},
          {EncodableValue("color"), EncodableValue(color)},
      }));
    }
  }
  const bool popup_hidden = !bot.popup || !IsWindowVisible(bot.popup);
  return EncodableValue(EncodableMap{
      {EncodableValue("probes"), EncodableValue(probes)},
      {EncodableValue("headerColor"), EncodableValue(ArgbOf(bot.background))},
      {EncodableValue("popupHidden"), EncodableValue(popup_hidden)},
      // The popup covers the client area.
      {EncodableValue("popupOrigin"),
       EncodableValue(EncodableList{EncodableValue(0.0), EncodableValue(0.0)})},
      {EncodableValue("leading"),
       EncodableValue(EncodableMap{
           {EncodableValue("shown"), EncodableValue(LeadingShown(bot))},
           {EncodableValue("hasIcon"), EncodableValue(bot.icon != nullptr)},
           {EncodableValue("back"),
            EncodableValue(LeadingShown(bot) && bot.can_go_back)},
       })},
      {EncodableValue("width"),
       EncodableValue(static_cast<double>(client.right / ScaleOf(bot.window)))},
  });
}

// Sends the message a real mouse would, to the window under the point.
void DebugMouse(const BotWindow& bot, const EncodableMap& arguments) {
  const EncodableValue* x = Lookup(arguments, "x");
  const EncodableValue* y = Lookup(arguments, "y");
  POINT point = DebugPoint(
      bot, EncodableValue(EncodableList{x ? *x : EncodableValue(0.0),
                                        y ? *y : EncodableValue(0.0)}));
  const std::string role = RoleAt(bot, point);
  HWND target = bot.window;
  if (role == "popup") {
    // The popup and its view sit at the client origin.
    target = ViewWindow(bot.popup_view);
  } else if (role == "capsule") {
    target = bot.capsule;
    MapWindowPoints(bot.window, target, &point, 1);
  }
  const EncodableValue* type_value = Lookup(arguments, "type");
  const auto* type = type_value ? std::get_if<std::string>(type_value) : nullptr;
  UINT message = WM_MOUSEMOVE;
  WPARAM buttons = 0;
  if (type && *type == "down") {
    message = WM_LBUTTONDOWN;
    buttons = MK_LBUTTON;
  } else if (type && *type == "up") {
    message = WM_LBUTTONUP;
  } else {
    // Flutter drops a hover where the pointer was just added, and Windows
    // removes it again once queued messages run, the real cursor being
    // elsewhere: the move needs a step before the point.
    SendMessageW(target, message, buttons, MAKELPARAM(point.x - 1, point.y));
  }
  SendMessageW(target, message, buttons, MAKELPARAM(point.x, point.y));
}
#endif

void Handle(const flutter::MethodCall<EncodableValue>& call,
            std::unique_ptr<flutter::MethodResult<EncodableValue>> result) {
  const auto* arguments = std::get_if<EncodableMap>(call.arguments());
  const auto browser =
      arguments ? GetInt(*arguments, "browserId") : std::nullopt;
  BotWindow* bot = browser ? Find(*browser) : nullptr;
  if (!bot) {
    result->Error("no_window", "Unknown browser window");
    return;
  }
  const std::string& method = call.method_name();
  if (method == "setChrome") {
    SetChrome(*bot, *arguments);
    InvalidateHeader(*bot);
    RenderCapsule(*bot);
    result->Success();
  } else if (method == "showPopup") {
    auto popup = ShowPopup(*bot, GetInt(*arguments, "engineId").value_or(0));
    if (popup) {
      result->Success(*popup);
    } else {
      result->Error("unsupported", "This Flutter engine cannot add views");
    }
  } else if (method == "hidePopup") {
    HidePopup(*bot);
    result->Success();
  } else if (method == "focus") {
    Focus(*bot);
    result->Success(EncodableValue(true));
#ifndef NDEBUG
  } else if (method == "debugProbe") {
    result->Success(DebugProbe(*bot, *arguments));
  } else if (method == "debugMouse") {
    DebugMouse(*bot, *arguments);
    result->Success();
#endif
  } else {
    result->NotImplemented();
  }
}

}  // namespace

void Install(flutter::BinaryMessenger* messenger) {
  static ULONG_PTR gdiplus = 0;
  const Gdiplus::GdiplusStartupInput input;
  Gdiplus::GdiplusStartup(&gdiplus, &input, nullptr);
  BufferedPaintInit();
  RegisterWindowClass(kCapsuleClass, CapsuleProc, 0);
  RegisterWindowClass(kPopupClass, PopupProc, 0);

  channel = std::make_unique<flutter::MethodChannel<EncodableValue>>(
      messenger, "one.mixin/bot_window",
      &flutter::StandardMethodCodec::GetInstance());
  channel->SetMethodCallHandler(Handle);

  static const DWWComposer composer{nullptr, Compose, NavigationChanged, Layout,
                                    Closing};
  dww_set_composer(&composer);
}

}  // namespace bot_window_composer
