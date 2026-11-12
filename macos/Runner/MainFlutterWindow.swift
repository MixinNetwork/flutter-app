import Cocoa
import FlutterMacOS
import window_manager

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    #if arch(x86_64)
    useSkia()
    #endif
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)
    RegisterGeneratedPlugins(registry: flutterViewController)
    PlatformMenuPlugin.register(with: flutterViewController.registrar(forPlugin: "PlatformMenuPlugin"))
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

// Impeller corrupts the screen on Intel Macs, so they keep Skia. A universal
// build shares one Info.plist, so this replaces the engine's private getter
// that reads FLTEnableImpeller. It patches FlutterDartProject itself: a
// subclass makes the engine look for icudtl.dat in the app bundle, and text
// layout then runs without ICU data.
private func useSkia() {
  let block: @convention(block) (AnyObject) -> Bool = { _ in false }
  class_replaceMethod(
    FlutterDartProject.self, NSSelectorFromString("enableImpeller"),
    imp_implementationWithBlock(block), "c@:")
}
