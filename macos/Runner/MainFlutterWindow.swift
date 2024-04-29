import Cocoa
import FlutterMacOS
import window_manager

extension utsname {
    static var sMachine: String {
        var utsname = utsname()
        uname(&utsname)
        return withUnsafePointer(to: &utsname.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: Int(_SYS_NAMELEN)) {
                String(cString: $0)
            }
        }
    }
    static var isAppleSilicon: Bool {
        sMachine == "arm64"
    }
}

class CustomFlutterDartProject : FlutterDartProject {
    
    @objc func enableImpeller() -> Bool {
        let isAppleSilicon = utsname.isAppleSilicon
        debugPrint("isAppleSilicon: \(isAppleSilicon)")
        // only enable Impeller on apple silicon
        return isAppleSilicon
    }
    
}

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
      
    let project = CustomFlutterDartProject()
    let engine = FlutterEngine(name: "io.flutter", project: project)
    let flutterViewController = FlutterViewController(engine: engine, nibName: nil, bundle: nil)
      
    let windowFrame = self.frame
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
    
    self.setFrameAutosaveName("mixin_messenger")

    super.awakeFromNib()
  }

  override public func order(_ place: NSWindow.OrderingMode, relativeTo otherWin: Int) {
    super.order(place, relativeTo: otherWin)
    hiddenWindowAtLaunch()
  }

}
