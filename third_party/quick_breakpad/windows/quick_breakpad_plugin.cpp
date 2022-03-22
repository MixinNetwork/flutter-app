#include "include/quick_breakpad/quick_breakpad_plugin.h"

// This must be included before many other Windows headers.
#include <windows.h>

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include <map>
#include <memory>
#include <iostream>

#include "client/windows/handler/exception_handler.h"

namespace {

class QuickBreakpadPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  QuickBreakpadPlugin();

  ~QuickBreakpadPlugin() override;

 private:

  google_breakpad::ExceptionHandler exception_handler_;

  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
};

// static
void QuickBreakpadPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows *registrar) {
  auto channel =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          registrar->messenger(), "quick_breakpad",
          &flutter::StandardMethodCodec::GetInstance());

  auto plugin = std::make_unique<QuickBreakpadPlugin>();

  channel->SetMethodCallHandler(
      [plugin_pointer = plugin.get()](const auto &call, auto result) {
        plugin_pointer->HandleMethodCall(call, std::move(result));
      });

  registrar->AddPlugin(std::move(plugin));
}

bool dumpCallback(
    const wchar_t *dump_path,
    const wchar_t *minidump_id,
    void *context,
    EXCEPTION_POINTERS *exinfo,
    MDRawAssertionInfo *assertion,
    bool succeeded
) {
  std::wcout << L"dump_path: " << dump_path << std::endl;
  std::wcout << L"minidump_id: " << minidump_id << std::endl;
  return succeeded;
}

QuickBreakpadPlugin::QuickBreakpadPlugin()
    : exception_handler_(L".", nullptr, dumpCallback, nullptr,
                         google_breakpad::ExceptionHandler::HANDLER_ALL) {

}

QuickBreakpadPlugin::~QuickBreakpadPlugin() = default;

void QuickBreakpadPlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  if (method_call.method_name() == "setDumpPath") {
    auto path = std::get_if<std::string>(method_call.arguments());
    if (!path) {
      result->Error("InvalidArguments", "Dump path must be a string");
      return;
    }

    auto new_size = path->size() + 1;
    auto *w_path = new wchar_t[new_size];
    mbstowcs_s(nullptr, w_path, new_size, path->c_str(), _TRUNCATE);
    exception_handler_.set_dump_path(w_path);
    delete[] w_path;
    result->Success();
  } else {
    result->NotImplemented();
  }
}

}  // namespace

void QuickBreakpadPluginRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  QuickBreakpadPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
