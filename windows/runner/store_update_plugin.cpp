#include "store_update_plugin.h"

// unknwn.h must come before the C++/WinRT headers for classic COM interop.
#include <unknwn.h>
#include <appmodel.h>
#include <shobjidl.h>

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>
#include <winrt/Windows.Foundation.Collections.h>
#include <winrt/Windows.Foundation.h>
#include <winrt/Windows.Services.Store.h>

#include <functional>
#include <memory>
#include <optional>
#include <string>

namespace {

using flutter::EncodableValue;
using winrt::Windows::Foundation::AsyncStatus;
using winrt::Windows::Foundation::Collections::IVectorView;
using winrt::Windows::Services::Store::StoreContext;
using winrt::Windows::Services::Store::StorePackageUpdate;
using winrt::Windows::Services::Store::StorePackageUpdateResult;
using winrt::Windows::Services::Store::StorePackageUpdateState;
using winrt::Windows::Services::Store::StorePackageUpdateStatus;

using Result = std::shared_ptr<flutter::MethodResult<EncodableValue>>;

// Carries a task from a WinRT thread to the platform thread.
constexpr UINT kRunTaskMessage = WM_APP + 0x5d1;

bool HasPackageIdentity() {
  UINT32 length = 0;
  return GetCurrentPackageFullName(&length, nullptr) !=
         APPMODEL_ERROR_NO_PACKAGE;
}

std::string ErrorMessage(const winrt::hresult_error& error) {
  return winrt::to_string(error.message());
}

// Runs |task| on the platform thread. Callable from any thread.
void Post(HWND hwnd, std::function<void()> task) {
  auto pointer = new std::function<void()>(std::move(task));
  if (!PostMessage(hwnd, kRunTaskMessage, 0,
                   reinterpret_cast<LPARAM>(pointer))) {
    delete pointer;  // The window is gone.
  }
}

class StoreUpdatePlugin : public flutter::Plugin {
 public:
  StoreUpdatePlugin(flutter::PluginRegistrarWindows* registrar, HWND hwnd)
      : registrar_(registrar),
        hwnd_(hwnd),
        channel_(std::make_unique<flutter::MethodChannel<EncodableValue>>(
            registrar->messenger(), "mixin_desktop/store_update",
            &flutter::StandardMethodCodec::GetInstance())) {
    channel_->SetMethodCallHandler([this](const auto& call, auto result) {
      HandleMethodCall(call, Result(std::move(result)));
    });
    proc_id_ = registrar_->RegisterTopLevelWindowProcDelegate(
        [](HWND, UINT message, WPARAM, LPARAM lparam)
            -> std::optional<LRESULT> {
          if (message != kRunTaskMessage) return std::nullopt;
          std::unique_ptr<std::function<void()>> task(
              reinterpret_cast<std::function<void()>*>(lparam));
          (*task)();
          return 0;
        });
  }

  ~StoreUpdatePlugin() override {
    registrar_->UnregisterTopLevelWindowProcDelegate(proc_id_);
  }

  StoreUpdatePlugin(const StoreUpdatePlugin&) = delete;
  StoreUpdatePlugin& operator=(const StoreUpdatePlugin&) = delete;

 private:
  // Null when the app is not packaged.
  StoreContext Context() {
    if (!context_ && HasPackageIdentity()) {
      auto context = StoreContext::GetDefault();
      // A desktop app must give the Store the window for its dialogs.
      winrt::check_hresult(
          context.as<::IInitializeWithWindow>()->Initialize(hwnd_));
      context_ = context;
    }
    return context_;
  }

  void HandleMethodCall(const flutter::MethodCall<EncodableValue>& call,
                        Result result) {
    try {
      if (call.method_name() == "storeUpdateCount") {
        UpdateCount(result);
      } else if (call.method_name() == "installStoreUpdates") {
        Install(result);
      } else {
        result->NotImplemented();
      }
    } catch (const winrt::hresult_error& error) {
      result->Error("store_error", ErrorMessage(error));
    }
  }

  // Succeeds with the number of updates, or with null when not packaged.
  void UpdateCount(Result result) {
    auto context = Context();
    if (!context) {
      result->Success();
      return;
    }
    auto operation = context.GetAppAndOptionalStorePackageUpdatesAsync();
    // The WinRT handlers run on a thread pool thread and may outlive the
    // plugin, so they use only copies. A posted task runs only while the
    // plugin's window proc delegate is registered.
    operation.Completed([this, hwnd = hwnd_, result](const auto& done,
                                                      AsyncStatus) {
      try {
        auto updates = done.GetResults();
        Post(hwnd, [this, result, updates] {
          updates_ = updates;
          result->Success(EncodableValue(static_cast<int64_t>(updates.Size())));
        });
      } catch (const winrt::hresult_error& error) {
        auto message = ErrorMessage(error);
        Post(hwnd, [result, message] {
          result->Error("store_error", message);
        });
      }
    });
  }

  // Succeeds when the Store installed the updates of the last count.
  // Sends "progress" from 0 to 1 while it runs.
  void Install(Result result) {
    auto context = Context();
    if (!context || !updates_ || updates_.Size() == 0) {
      result->Error("no_updates", "storeUpdateCount found no updates");
      return;
    }
    auto operation =
        context.RequestDownloadAndInstallStorePackageUpdatesAsync(updates_);
    operation.Progress([this, hwnd = hwnd_](
                           const auto&, const StorePackageUpdateStatus& status) {
      double progress = status.TotalDownloadProgress;
      Post(hwnd, [this, progress] {
        channel_->InvokeMethod(
            "progress", std::make_unique<EncodableValue>(progress));
      });
    });
    operation.Completed([hwnd = hwnd_, result](const auto& done, AsyncStatus) {
      try {
        auto state = done.GetResults().OverallState();
        Post(hwnd, [result, state] {
          if (state == StorePackageUpdateState::Completed) {
            result->Success();
          } else {
            // Canceled, OtherError, ErrorLowBattery, ErrorWiFiRequired, ...
            result->Error("store_state",
                          std::to_string(static_cast<int>(state)));
          }
        });
      } catch (const winrt::hresult_error& error) {
        auto message = ErrorMessage(error);
        Post(hwnd, [result, message] {
          result->Error("store_error", message);
        });
      }
    });
  }

  flutter::PluginRegistrarWindows* registrar_;
  HWND hwnd_;
  std::unique_ptr<flutter::MethodChannel<EncodableValue>> channel_;
  int proc_id_ = 0;
  StoreContext context_{nullptr};
  IVectorView<StorePackageUpdate> updates_{nullptr};
};

}  // namespace

void StoreUpdatePluginRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar_ref, HWND hwnd) {
  auto registrar = flutter::PluginRegistrarManager::GetInstance()
                       ->GetRegistrar<flutter::PluginRegistrarWindows>(
                           registrar_ref);
  registrar->AddPlugin(std::make_unique<StoreUpdatePlugin>(registrar, hwnd));
}
