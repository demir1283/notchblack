import AppKit
import os.log

/// Hammerspoon (veya baska bir otomasyon araci) icin kontrol araligi.
///
/// Iki kanal dinler:
/// 1. Distributed notification "local.notchblack.command" - hafif, odak
///    calmaz, uygulama zaten acikken kullanilir.
/// 2. notchblack:// URL scheme - uygulama kapaliysa onu baslatir
///    (distributed notification uygulama kapaliyken kaybolur).
///
/// Islem bitince "local.notchblack.didRefresh" bildirimini yayinlar;
/// Hammerspoon bunu dinleyip bir sonraki adima gecebilir.
final class HammerspoonBridge {

    static let commandNotification = Notification.Name("local.notchblack.command")
    static let didRefreshNotification = "local.notchblack.didRefresh"

    private let screenManager: ScreenManager

    init(screenManager: ScreenManager) {
        self.screenManager = screenManager
        DistributedNotificationCenter.default().addObserver(
            self, selector: #selector(handleCommand(_:)),
            name: HammerspoonBridge.commandNotification, object: nil
        )
        NSAppleEventManager.shared().setEventHandler(
            self, andSelector: #selector(handleURLEvent(_:replyEvent:)),
            forEventClass: AEEventClass(kInternetEventClass),
            andEventID: AEEventID(kAEGetURL)
        )
    }

    deinit {
        DistributedNotificationCenter.default().removeObserver(self)
    }

    @objc private func handleCommand(_ note: Notification) {
        guard let info = note.userInfo,
              let cmd = info["cmd"] as? String else { return }
        let display = info["display"] as? String
        perform(cmd: cmd, display: display)
    }

    /// notchblack://refresh?display=all  gibi URL'leri isler.
    @objc private func handleURLEvent(_ event: NSAppleEventDescriptor, replyEvent: NSAppleEventDescriptor) {
        guard let urlString = event.paramDescriptor(forKeyword: AEKeyword(keyDirectObject))?.stringValue,
              let components = URLComponents(string: urlString) else { return }

        let cmd = components.host ?? "refresh"
        let display = components.queryItems?.first(where: { $0.name == "display" })?.value
        perform(cmd: cmd, display: display)
    }

    private func perform(cmd: String, display: String?) {
        let scope = ScreenManager.Scope.parse(display)
        log.info("Hammerspoon command: \(cmd, privacy: .public) display=\(display ?? "all", privacy: .public)")

        switch cmd.lowercased() {
        case "refresh":
            screenManager.rebuild(scope: scope)
        case "on":
            screenManager.setEnabled(true, scope: scope)
        case "off":
            screenManager.setEnabled(false, scope: scope)
        case "toggle":
            screenManager.toggle(scope: scope)
        case "status":
            break // asagida didRefresh ile zaten mevcut durum yayinlanir
        default:
            log.info("Bilinmeyen komut: \(cmd, privacy: .public)")
            return
        }

        postDidRefresh()
    }

    private func postDidRefresh() {
        DistributedNotificationCenter.default().postNotificationName(
            Notification.Name(HammerspoonBridge.didRefreshNotification),
            object: nil,
            userInfo: ["screens": screenManager.activeScreenUUIDs],
            deliverImmediately: true
        )
    }
}
