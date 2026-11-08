import Cocoa
import FlutterMacOS
import StoreKit
import mixin_logger
import window_manager

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController(project: RendererProject())
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)
    RegisterGeneratedPlugins(registry: flutterViewController)
    PlatformMenuPlugin.register(with: flutterViewController.registrar(forPlugin: "PlatformMenuPlugin"))
    AppUpdatePlugin.register(with: flutterViewController.registrar(forPlugin: "AppUpdatePlugin"))
    // Before the first browser window is created.
    BotWindowComposer.install(controller: flutterViewController)
    self.titleVisibility = .hidden
    self.titlebarAppearsTransparent = true
    self.styleMask = [self.styleMask, NSWindow.StyleMask.fullSizeContentView]

    self.isOpaque = false
    self.backgroundColor = NSColor(calibratedWhite: 1.0, alpha: 0.5)
    self.isReleasedWhenClosed = false
    
    self.setFrameAutosaveName("mixin_messenger")

    super.awakeFromNib()
  }

  override public func order(_ place: NSWindow.OrderingMode, relativeTo otherWin: Int) {
    super.order(place, relativeTo: otherWin)
    hiddenWindowAtLaunch()
  }

}

// Only the DMG build has Sparkle: CI copies it into Contents/Frameworks
// (dist/macos_sparkle.sh), so the App Store build has no self-updater. Sparkle
// is loaded at run time and called through mirrors of its Objective-C API.
@objc private protocol SparkleUpdater {
  @objc(initWithHostBundle:applicationBundle:userDriver:delegate:)
  init(hostBundle: Bundle, applicationBundle: Bundle, userDriver: AnyObject, delegate: AnyObject?)
  @objc(startUpdater:) func startUpdater() throws
  func checkForUpdates()
}

private let sparklePath = Bundle.main.privateFrameworksPath! + "/Sparkle.framework"
private let sparkleInstall = 1 // SPUUserUpdateChoiceInstall

class AppUpdatePlugin: NSObject, FlutterPlugin {
  private let channel: FlutterMethodChannel
  private var updater: AnyObject?
  private var feedURL: String?
  private var result: FlutterResult?
  private var expectedLength: UInt64 = 0
  private var receivedLength: UInt64 = 0
  private var percent = -1

  init(channel: FlutterMethodChannel) {
    self.channel = channel
  }

  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "mixin_desktop/app_update", binaryMessenger: registrar.messenger)
    registrar.addMethodCallDelegate(AppUpdatePlugin(channel: channel), channel: channel)
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "channel":
      let receipt = Bundle.main.appStoreReceiptURL.map {
        FileManager.default.fileExists(atPath: $0.path)
      } ?? false
      let key = Bundle.main.object(forInfoDictionaryKey: "SUPublicEDKey") as? String ?? ""
      let sparkle = !key.isEmpty && FileManager.default.fileExists(atPath: sparklePath)
      Task { @MainActor in
        var environment: String?
        if receipt { environment = await self.storeEnvironment() }
        result(["environment": environment as Any, "sparkle": sparkle])
      }
    case "install":
      install(feedURL: call.arguments as! String, result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  // On macOS the receipt file is always named receipt, also for TestFlight, so
  // ask StoreKit: TestFlight builds are in the Sandbox environment.
  // nil on macOS 12, where AppTransaction is missing and TestFlight cannot be
  // told from the App Store, so the app shows no update item.
  private func storeEnvironment() async -> String? {
    guard #available(macOS 13.0, *) else { return nil }
    do {
      switch try await AppTransaction.shared {
      case .verified(let transaction), .unverified(let transaction, _):
        return transaction.environment.rawValue
      }
    } catch {
      mixin_logger_write_log("app update: no app transaction: \(error)")
      return "Production"
    }
  }

  private func install(feedURL: String, result: @escaping FlutterResult) {
    self.feedURL = feedURL
    self.result = result
    do {
      if updater == nil {
        guard let bundle = Bundle(path: sparklePath) else { throw error("no Sparkle.framework") }
        try bundle.loadAndReturnError()
        guard let cls = NSClassFromString("SPUUpdater") else { throw error("no SPUUpdater") }
        class_addProtocol(cls, SparkleUpdater.self)
        let updater = (cls as! SparkleUpdater.Type).init(
          hostBundle: .main, applicationBundle: .main, userDriver: self, delegate: self)
        try updater.startUpdater()
        self.updater = updater
      }
      (updater as! SparkleUpdater).checkForUpdates()
    } catch {
      finish(error)
    }
  }

  private func error(_ message: String) -> NSError {
    NSError(domain: "AppUpdate", code: 0, userInfo: [NSLocalizedDescriptionKey: message])
  }

  private func finish(_ error: Error) {
    mixin_logger_write_log("app update: \(error)")
    result?(FlutterError(code: "update", message: error.localizedDescription, details: nil))
    result = nil
  }

  // SPUUpdaterDelegate

  @objc(feedURLStringForUpdater:) func feedURLString(for updater: AnyObject) -> String? { feedURL }

  // SPUUserDriver: answers yes to every step and shows nothing; the sidebar
  // item shows the progress.

  // Not called: SUEnableAutomaticChecks is NO, so Sparkle asks no permission.
  @objc(showUpdatePermissionRequest:reply:)
  func showUpdatePermissionRequest(_ request: AnyObject, reply: @escaping (AnyObject) -> Void) {}

  @objc(showUserInitiatedUpdateCheckWithCancellation:)
  func showUserInitiatedUpdateCheck(cancellation: @escaping () -> Void) {}

  @objc(showUpdateFoundWithAppcastItem:state:reply:)
  func showUpdateFound(_ item: NSObject, state: AnyObject, reply: @escaping (Int) -> Void) {
    mixin_logger_write_log("app update: found \(item.value(forKey: "versionString") ?? "?")")
    reply(sparkleInstall)
  }

  @objc(showUpdateReleaseNotesWithDownloadData:)
  func showUpdateReleaseNotes(_ data: AnyObject) {}

  @objc(showUpdateReleaseNotesFailedToDownloadWithError:)
  func showUpdateReleaseNotesFailedToDownload(_ error: Error) {}

  @objc(showUpdateNotFoundWithError:acknowledgement:)
  func showUpdateNotFound(_ error: Error, acknowledgement: @escaping () -> Void) {
    finish(error)
    acknowledgement()
  }

  @objc(showUpdaterError:acknowledgement:)
  func showUpdaterError(_ error: Error, acknowledgement: @escaping () -> Void) {
    finish(error)
    acknowledgement()
  }

  @objc(showDownloadInitiatedWithCancellation:)
  func showDownloadInitiated(cancellation: @escaping () -> Void) {
    expectedLength = 0
    receivedLength = 0
    percent = -1
  }

  @objc(showDownloadDidReceiveExpectedContentLength:)
  func showDownloadDidReceiveExpectedContentLength(_ length: UInt64) {
    expectedLength = length
  }

  @objc(showDownloadDidReceiveDataOfLength:)
  func showDownloadDidReceiveData(ofLength length: UInt64) {
    receivedLength += length
    guard expectedLength > 0 else { return }
    let percent = Int(min(receivedLength * 100 / expectedLength, 100))
    if percent != self.percent {
      self.percent = percent
      channel.invokeMethod("progress", arguments: Double(percent) / 100)
    }
  }

  @objc func showDownloadDidStartExtractingUpdate() {}

  @objc(showExtractionReceivedProgress:)
  func showExtractionReceivedProgress(_ progress: Double) {}

  @objc(showReadyToInstallAndRelaunch:)
  func showReadyToInstallAndRelaunch(_ reply: @escaping (Int) -> Void) {
    mixin_logger_write_log("app update: install and relaunch")
    reply(sparkleInstall)
  }

  @objc(showInstallingUpdateWithApplicationTerminated:retryTerminatingApplication:)
  func showInstallingUpdate(applicationTerminated: Bool, retryTerminatingApplication: @escaping () -> Void) {}

  @objc(showUpdateInstalledAndRelaunched:acknowledgement:)
  func showUpdateInstalledAndRelaunched(_ relaunched: Bool, acknowledgement: @escaping () -> Void) {
    acknowledgement()
  }

  @objc func dismissUpdateInstallation() {}
}

// Impeller corrupts the screen on Intel Macs, so they keep Skia. A universal
// build shares one Info.plist, so this overrides the engine's private getter
// that reads FLTEnableImpeller.
private final class RendererProject: FlutterDartProject {
  #if arch(x86_64)
  @objc func enableImpeller() -> Bool { false }
  #endif
}
