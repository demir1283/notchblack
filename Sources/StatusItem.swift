import AppKit
import ServiceManagement

/// Menu cubugundaki kucuk kontrol simgesi: ekran basina aç/kapat ve cikis.
/// Kendi siyah seridimizin UZERINE DEGIL, sistemin kalan menu cubuğu
/// alanina (sag tarafa) yerlesir - NSStatusItem bunu otomatik yonetir.
final class StatusItem: NSObject, NSMenuDelegate {

    private let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    private let screenManager: ScreenManager

    init(screenManager: ScreenManager) {
        self.screenManager = screenManager
        super.init()

        if let button = item.button {
            button.image = NSImage(
                systemSymbolName: "rectangle.bottomthird.inset.filled",
                accessibilityDescription: "NotchBlack"
            )
        }

        let menu = NSMenu()
        menu.delegate = self
        item.menu = menu
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()

        guard let screen = NSScreen.main, let uuid = ScreenManager.uuid(for: screen) else {
            menu.addItem(withTitle: "Ekran bulunamadı", action: nil, keyEquivalent: "")
            menu.addItem(.separator())
            menu.addItem(withTitle: "Çıkış", action: #selector(quit), keyEquivalent: "q")
            return
        }

        let enabled = screenManager.isEnabled(uuid)
        let toggleTitle = enabled ? "Bu Ekranda Kapat" : "Bu Ekranda Aç"
        let toggleItem = NSMenuItem(title: toggleTitle, action: #selector(toggleCurrentScreen), keyEquivalent: "")
        toggleItem.target = self
        menu.addItem(toggleItem)

        let allOnItem = NSMenuItem(title: "Tüm Ekranlarda Aç", action: #selector(allOn), keyEquivalent: "")
        allOnItem.target = self
        menu.addItem(allOnItem)

        let allOffItem = NSMenuItem(title: "Tüm Ekranlarda Kapat", action: #selector(allOff), keyEquivalent: "")
        allOffItem.target = self
        menu.addItem(allOffItem)

        menu.addItem(.separator())

        let loginItem = NSMenuItem(title: "Girişte Başlat", action: #selector(toggleLoginItem), keyEquivalent: "")
        loginItem.target = self
        loginItem.state = (SMAppService.mainApp.status == .enabled) ? .on : .off
        menu.addItem(loginItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(title: "Çıkış", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
    }

    @objc private func toggleLoginItem() {
        do {
            if SMAppService.mainApp.status == .enabled {
                try SMAppService.mainApp.unregister()
            } else {
                try SMAppService.mainApp.register()
            }
        } catch {
            log.error("Login item degistirilemedi: \(error.localizedDescription, privacy: .public)")
        }
    }

    @objc private func toggleCurrentScreen() {
        guard let screen = NSScreen.main, let uuid = ScreenManager.uuid(for: screen) else { return }
        screenManager.setEnabled(!screenManager.isEnabled(uuid), scope: .uuid(uuid))
    }

    @objc private func allOn() {
        screenManager.setEnabled(true, scope: .all)
    }

    @objc private func allOff() {
        screenManager.setEnabled(false, scope: .all)
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
