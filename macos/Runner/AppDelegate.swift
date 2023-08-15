import Cocoa
import FlutterMacOS

@NSApplicationMain
class AppDelegate: FlutterAppDelegate {
    private var activity: NSObjectProtocol?

    override func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if let window = mainFlutterWindow {
            window.makeKeyAndOrderFront(self)
            return true
        }
        return false
    }

    override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }

    override func applicationDidBecomeActive(_ notification: Notification) {
        signal(SIGPIPE, SIG_IGN)
    }

    override func applicationWillResignActive(_ notification: Notification) {
        signal(SIGPIPE, SIG_IGN)
    }

    override func applicationDidFinishLaunching(_ aNotification: Notification) {
        beginActivity()
    }

    override func applicationWillTerminate(_ aNotification: Notification) {
        endActivity()
    }

    private func beginActivity() {
        endActivity()
        activity = ProcessInfo.processInfo.beginActivity(options: .background, reason: "Receive new messages")
    }

    private func endActivity() {
        if activity == nil { return }
        ProcessInfo.processInfo.endActivity(activity!)
        activity = nil
    }
  
    @IBAction func onChatMenuClicked(_ sender: Any) {
        mainFlutterWindow?.makeKeyAndOrderFront(self)
    }
}
