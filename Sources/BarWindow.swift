import AppKit

/// Bir ekranin menu cubugu seridini kaplayan, tiklanamaz, siyah bir pencere.
/// Tek sorumlulugu bu: notch'u (veya menu cubugunu) siyaha boyamak.
///
/// Bilincli olarak koseleri YUVARLATILMAMIS duz bir dikdortgen: altindaki
/// pencerelerin kendi yuvarlak koseleri zaten bu siyah zeminin ustunde
/// goruntuleniyor. Ekranin fiziksel yuvarlak kose yaricapini resmi olmayan
/// bir API olmadan birebir yakalamak mumkun degil (denendi, macOS 27'de
/// bilinen private API yanit vermiyor) - kalan ufak (1-2px) kose boslugu,
/// resmi API'siz calisan butun benzer araclarin (TopNotch dahil) paylastigi
/// bilinen bir sinirlama.
final class BarWindow: NSWindow {

    init(screen: NSScreen) {
        let rect = BarWindow.frame(for: screen)

        super.init(
            contentRect: rect,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )

        backgroundColor = .black
        isOpaque = true
        hasShadow = false
        ignoresMouseEvents = true           // tiklamalar altindaki pencereye/menu cubuguna gecer
        isReleasedWhenClosed = false
        level = NSWindow.Level(
            rawValue: Int(CGWindowLevelForKey(.mainMenuWindow)) - 1
        )
        collectionBehavior = [
            .canJoinAllSpaces,
            .stationary,
            .ignoresCycle,
            .fullScreenNone
        ]
        isMovable = false

        orderFrontRegardless()
    }

    /// AppKit varsayilan olarak pencereleri menu cubugunu kapatmayacak
    /// sekilde kisitlar (constrain). Bizim amacimiz tam da onu kapatmak,
    /// bu yuzden bu kisitlamayi burada iptal ediyoruz.
    override func constrainFrameRect(_ frameRect: NSRect, to screen: NSScreen?) -> NSRect {
        frameRect
    }

    /// Ekranin ust seridinin (menu cubugu / notch) cercevesini hesaplar.
    /// Notch'suz ekranda bu yukseklik 0 olabilir - cagiran taraf bunu kontrol etmeli.
    static func frame(for screen: NSScreen) -> NSRect {
        let barHeight = barHeight(for: screen)
        let full = screen.frame
        return NSRect(
            x: full.minX,
            y: full.maxY - barHeight,
            width: full.width,
            height: barHeight
        )
    }

    /// Menu cubugu yuksekligi: notch'lu ekranda safeAreaInsets.top,
    /// degilse frame - visibleFrame farkindan hesaplanir.
    static func barHeight(for screen: NSScreen) -> CGFloat {
        if #available(macOS 12.0, *), screen.safeAreaInsets.top > 0 {
            return screen.safeAreaInsets.top
        }
        return screen.frame.maxY - screen.visibleFrame.maxY
    }

    /// Bu ekranda menu cubugu/notch icin gosterilecek bir serit var mi?
    static func shouldShow(on screen: NSScreen) -> Bool {
        barHeight(for: screen) > 0
    }

    /// Ekran yeniden boyutlandi / tasindi: cerceveyi yeniden hesapla.
    func updateFrame(for screen: NSScreen) {
        setFrame(BarWindow.frame(for: screen), display: true)
    }
}
