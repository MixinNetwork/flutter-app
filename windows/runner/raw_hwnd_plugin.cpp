#include "raw_hwnd_plugin.h"

// This must be included before many other Windows headers.
#include <windows.h>

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include <memory>
#include <cstdint>

namespace raw_hwnd {

class RawHwndPlugin : public flutter::Plugin {
 public:

  explicit RawHwndPlugin(HWND hwnd);

  ~RawHwndPlugin() override;

  // Disallow copy and assign.
  RawHwndPlugin(const RawHwndPlugin &) = delete;
  RawHwndPlugin &operator=(const RawHwndPlugin &) = delete;

  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

 private:

  HWND hwnd_;

};

RawHwndPlugin::RawHwndPlugin(HWND hwnd) : hwnd_(hwnd) {}

RawHwndPlugin::~RawHwndPlugin() = default;

void RawHwndPlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  if (method_call.method_name() == "getRawWindowHandle") {
    result->Success(flutter::EncodableValue(int64_t(hwnd_)));
  } else {
    result->NotImplemented();
  }
}

}  // namespace raw_hwnd


void RawHwndPluginRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrarRef, HWND handle) {
  auto registrar = flutter::PluginRegistrarManager::GetInstance()
      ->GetRegistrar<flutter::PluginRegistrarWindows>(registrarRef);
  auto channel =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          registrar->messenger(), "mixin_desktop/raw_hwnd",
          &flutter::StandardMethodCodec::GetInstance());
  auto plugin = std::make_unique<raw_hwnd::RawHwndPlugin>(handle);
  channel->SetMethodCallHandler(
      [plugin_pointer = plugin.get()](const auto &call, auto result) {
        plugin_pointer->HandleMethodCall(call, std::move(result));
      });
  registrar->AddPlugin(std::move(plugin));
}
