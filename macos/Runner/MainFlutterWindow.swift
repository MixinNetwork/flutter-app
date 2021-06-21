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
        
        self.titleVisibility = .hidden
        self.titlebarAppearsTransparent = true
        self.isReleasedWhenClosed = false
        self.styleMask = [self.styleMask, NSWindow.StyleMask.fullSizeContentView]
        self.isOpaque = false
        
        if #available(macOS 10.14, *) {
            // Adding a NSVisualEffectView to act as a translucent background
            let contentView = contentViewController!.view;
            let superView = contentView.superview!;
            
            let blurView = NSVisualEffectView(frame: superView.bounds)
            blurView.autoresizingMask = [.width, .height]
            blurView.blendingMode = .behindWindow
            blurView.material = .fullScreenUI
            blurView.state = .active
            
            // Pick the correct material for the task
            blurView.material = .underWindowBackground
            
            // Replace the contentView and the background view
            superView.replaceSubview(contentView, with: blurView)
            blurView.addSubview(contentView)
        }
        
        
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
