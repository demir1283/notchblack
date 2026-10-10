import AppKit
import os.log

/// Her ekran icin bir BarWindow kurar ve ekran durumundaki degisikliklere
/// (monitor tak/cikar, cozunurluk, Spaces, uyku/uyanma) tepki verir.
///
/// Olay tabanli calisir: timer yok, polling yok. Yalnizca sistem bildirimi
/// geldiginde uyanir, kisa bir debounce sonrasi pencereleri yeniden kurar.
///
/// Ekranlar kalici display UUID ile tanimlanir (CGDisplayCreateUUIDFromDisplayID).
/// Bu UUID, Hammerspoon'daki hs.screen:getUUID() ile ayni degeri verir -
/// boylece iki taraf ayni ekrana ayni adla seslenir.
final class ScreenManager {

    private var windows: [String: BarWindow] = [:]   // UUID -> pencere
    private var pendingRebuild: DispatchWorkItem?
    private let debounceInterval: TimeInterval = 0.25
    private let defaults = UserDefaults.standard
    private let prefPrefix = "local.notchblack.enabled."

    init() {
        observeNotifications()
        rebuild()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        NSWorkspace.shared.notificationCenter.removeObserver(self)
    }

    private func observeNotifications() {
        NotificationCenter.default.addObserver(
            self, selector: #selector(scheduleRebuild),
            name: NSApplication.didChangeScreenParametersNotification, object: nil
        )
        NSWorkspace.shared.notificationCenter.addObserver(
            self, selector: #selector(scheduleRebuild),
            name: NSWorkspace.activeSpaceDidChangeNotification, object: nil
        )
        NSWorkspace.shared.notificationCenter.addObserver(
            self, selector: #selector(scheduleRebuild),
            name: NSWorkspace.didWakeNotification, object: nil
        )
    }

    @objc private func scheduleRebuild() {
        pendingRebuild?.cancel()
        let work = DispatchWorkItem { [weak self] in self?.rebuild() }
        pendingRebuild = work
        DispatchQueue.main.asyncAfter(deadline: .now() + debounceInterval, execute: work)
    }

    /// Mevcut ekran listesini okur, tercihe gore her biri icin pencereyi
    /// kurar/gunceller, artik gecersiz olanlari kapatir. "display" verilirse
    /// (UUID / "builtin" / "all") yalnizca o kapsamdaki ekranlar etkilenir;
    /// nil ise tum ekranlar taranir (ör. monitor tak/cikar sonrasi).
    func rebuild(scope: ScreenManager.Scope = .all) {
        let currentScreens = NSScreen.screens
        let currentUUIDs = Set(currentScreens.compactMap(ScreenManager.uuid(for:)))

        for (id, window) in windows where !currentUUIDs.contains(id) {
            window.orderOut(nil)
            windows.removeValue(forKey: id)
        }

        for screen in currentScreens {
            guard let id = ScreenManager.uuid(for: screen) else { continue }
            guard scope.matches(uuid: id, screen: screen) else { continue }

            let shouldShow = BarWindow.shouldShow(on: screen) && isEnabled(id)
            guard shouldShow else {
                windows[id]?.orderOut(nil)
                windows.removeValue(forKey: id)
                continue
            }

            if let existing = windows[id] {
                existing.updateFrame(for: screen)
            } else {
                windows[id] = BarWindow(screen: screen)
            }
        }

        log.info("ScreenManager rebuild: \(self.windows.count, privacy: .public) pencere")
    }

    // MARK: - Hammerspoon komutlari

    func isEnabled(_ uuid: String) -> Bool {
        if defaults.object(forKey: prefPrefix + uuid) == nil { return true } // varsayilan: acik
        return defaults.bool(forKey: prefPrefix + uuid)
    }

    func setEnabled(_ enabled: Bool, scope: ScreenManager.Scope) {
        for screen in NSScreen.screens {
            guard let id = ScreenManager.uuid(for: screen), scope.matches(uuid: id, screen: screen) else { continue }
            defaults.set(enabled, forKey: prefPrefix + id)
        }
        rebuild(scope: scope)
    }

    func toggle(scope: ScreenManager.Scope) {
        for screen in NSScreen.screens {
            guard let id = ScreenManager.uuid(for: screen), scope.matches(uuid: id, screen: screen) else { continue }
            setEnabled(!isEnabled(id), scope: .uuid(id))
        }
    }

    /// Su an pencere olan ekranlarin UUID listesi (didRefresh bildiriminde kullanilir).
    var activeScreenUUIDs: [String] { Array(windows.keys) }

    // MARK: - Ekran kimligi

    enum Scope {
        case all
        case builtin
        case uuid(String)

        func matches(uuid: String, screen: NSScreen) -> Bool {
            switch self {
            case .all: return true
            case .builtin: return ScreenManager.isBuiltIn(screen)
            case .uuid(let target): return uuid == target
            }
        }

        static func parse(_ raw: String?) -> Scope {
            switch raw?.lowercased() {
            case nil, "all": return .all
            case "builtin": return .builtin
            case let other?: return .uuid(other)
            }
        }
    }

    static func uuid(for screen: NSScreen) -> String? {
        guard let id = displayID(for: screen),
              let cfuuid = CGDisplayCreateUUIDFromDisplayID(id)?.takeRetainedValue() else { return nil }
        return CFUUIDCreateString(nil, cfuuid) as String?
    }

    static func isBuiltIn(_ screen: NSScreen) -> Bool {
        guard let id = displayID(for: screen) else { return false }
        return CGDisplayIsBuiltin(id) != 0
    }

    private static func displayID(for screen: NSScreen) -> CGDirectDisplayID? {
        let key = NSDeviceDescriptionKey("NSScreenNumber")
        guard let value = screen.deviceDescription[key] as? NSNumber else { return nil }
        return value.uint32Value
    }
}
