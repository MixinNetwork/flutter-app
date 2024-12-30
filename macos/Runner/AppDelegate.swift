import Cocoa
import FlutterMacOS
import CrashReporter
import mixin_logger
import path_provider_foundation

@main
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
        
        let instance = PathProviderPlugin()
        let dir = getDirectory(ofType: .documentDirectory)
        if var dir = dir {
            let dir = (dir as NSString).appendingPathComponent("log")
            print("init mixin logger to \(dir)")
            mixin_logger_init(dir, 1024 * 1024 * 10 , 10, "")
            mixin_logger_write_log("log from native appstart")
        }
        
        let config = PLCrashReporterConfig(
            signalHandlerType: .mach,
            symbolicationStrategy: .all,
            shouldRegisterUncaughtExceptionHandler: true
        )
        guard let crashReporter = PLCrashReporter(configuration: config) else {
            print("could not create an instance of PLCrashReport")
            return
        }
        
        
        do {
            try crashReporter.enableAndReturnError()
        } catch let error {
            print("Warning: Could not enable crash reporter: \(error)")
        }
        
        if crashReporter.hasPendingCrashReport() {
            do {
                let data = try crashReporter.loadPendingCrashReportDataAndReturnError()
                
                // Retrieving crash reporter data.
                let report = try PLCrashReport(data: data)
                
                // We could send the report from here, but we'll just print out some debugging info instead.
                if let text = PLCrashReportTextFormatter.stringValue(for: report, with: PLCrashReportTextFormatiOS) {
                    print(text)
                    mixin_logger_write_log("native crash occurred: \(Date())")
                    mixin_logger_write_log(text)
                } else {
                    print("CrashReporter: can't convert report to text")
                }
            } catch let error {
                print("CrashReporter failed to load and parse with error: \(error)")
            }
        }
        
        crashReporter.purgePendingCrashReport()
    }
    
    override func applicationWillTerminate(_ aNotification: Notification) {
        endActivity()
    }
    
    override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
      return true
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




private func getDirectory(ofType directory: FileManager.SearchPathDirectory) -> String? {
  let paths = NSSearchPathForDirectoriesInDomains(
    directory,
    FileManager.SearchPathDomainMask.userDomainMask,
    true)
  return paths.first
}
