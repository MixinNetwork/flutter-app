import Cocoa
import FlutterMacOS

@NSApplicationMain
class AppDelegate: FlutterAppDelegate {
  override func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
    if flag {
      return false
    } else {
      mainFlutterWindow?.makeKeyAndOrderFront(self)
      return true
    }
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
}
