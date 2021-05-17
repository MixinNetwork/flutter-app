import Cocoa
import FlutterMacOS

@NSApplicationMain
class AppDelegate: FlutterAppDelegate {
  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  override func applicationDidBecomeActive(_ notification: Notification) {
    signal(SIGPIPE, SIG_IGN);
  }

  override func applicationWillResignActive(_ notification: Notification) {
    signal(SIGPIPE, SIG_IGN);
  }
}
