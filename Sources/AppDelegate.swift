import AppKit
import os.log

let log = Logger(subsystem: "local.notchblack", category: "app")

final class AppDelegate: NSObject, NSApplicationDelegate {

    private var screenManager: ScreenManager?
    private var hammerspoonBridge: HammerspoonBridge?
    private var statusItem: StatusItem?

    func applicationDidFinishLaunching(_ notification: Notification) {
        log.info("NotchBlack started")
        let manager = ScreenManager()
        screenManager = manager
        hammerspoonBridge = HammerspoonBridge(screenManager: manager)
        statusItem = StatusItem(screenManager: manager)
    }

    func applicationWillTerminate(_ notification: Notification) {
        log.info("NotchBlack terminating")
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }
}
