import bitsdojo_window_macos
import Cocoa
import FlutterMacOS

class MainFlutterWindow: BitsdojoWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.minSize = NSSize(width: 460, height: 320)
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)
    RegisterGeneratedPlugins(registry: flutterViewController)
    PlatformMenuPlugin.register(with: flutterViewController.registrar(forPlugin: "PlatformMenuPlugin"))
    self.titleVisibility = .hidden
    self.titlebarAppearsTransparent = true
    self.styleMask = [self.styleMask, NSWindow.StyleMask.fullSizeContentView]

    self.isOpaque = false
    self.backgroundColor = NSColor(calibratedWhite: 1.0, alpha: 0.5)
    self.isReleasedWhenClosed = false
    
    self.setContentSize(NSSize(width: 1280, height: 750))
    self.setFrameAutosaveName("mixin_messenger")

    super.awakeFromNib()
  }

  override func bitsdojo_window_configure() -> UInt {
    return BDW_CUSTOM_FRAME | BDW_HIDE_ON_STARTUP
  }

  public func dummyMethodToEnforceBundling() {
    // This will never be executed
    #if RELEASE
    setWindowCanBeShown(true)
    #endif
  }
}
