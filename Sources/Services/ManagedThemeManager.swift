import SwiftUI
import AppKit
import Foundation

/// Brand colors only; health/warning/critical semantic indicators are never overridden.
/// Periodic reconciliation covers MDM changes that do not send process notifications.
final class ManagedThemeManager: ObservableObject {
    static let shared = ManagedThemeManager()
    @Published private(set) var revision = 0
    @Published private(set) var palette = Palette.default
    private var timer: Timer?
    private var signature = ""

    struct Palette: Equatable {
        var primary: String?
        var secondary: String?
        var accent: String?
        var selection: String?
        static let `default` = Palette()
    }

    private init() { reconcile(); start() }

    func start() {
        guard timer == nil else { return }
        timer = Timer.scheduledTimer(withTimeInterval: 15, repeats: true) { [weak self] _ in
            self?.reconcile()
        }
        NotificationCenter.default.addObserver(self, selector: #selector(refresh),
            name: NSApplication.didBecomeActiveNotification, object: nil)
        DistributedNotificationCenter.default().addObserver(self, selector: #selector(refresh),
            name: UserDefaults.didChangeNotification, object: nil)
    }

    @objc private func refresh() { reconcile() }

    func reconcile() {
        // Explicit synchronization avoids relying on UserDefaults' potentially stale cache.
        CFPreferencesAppSynchronize(ManagedConfiguration.domain as CFString)
        func value(_ key: String) -> String? {
            guard let raw = ManagedConfiguration.managedBrandColor(key) else { return nil }
            return Self.validHex(raw)
        }
        let next = Palette(primary: value("BrandPrimaryColor"),
                           secondary: value("BrandSecondaryColor"),
                           accent: value("BrandAccentColor"),
                           selection: value("BrandSelectionColor"))
        guard next != palette else { return }
        palette = next
        revision &+= 1
    }

    static func validHex(_ raw: String) -> String? {
        let hex = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard hex.count == 7, hex.first == "#",
              hex.dropFirst().allSatisfy({ $0.isHexDigit }) else { return nil }
        return hex.uppercased()
    }

    static func color(_ hex: String?, fallback: Color) -> Color {
        guard let hex, let number = UInt64(hex.dropFirst(), radix: 16) else { return fallback }
        return Color(.sRGB, red: Double((number >> 16) & 255) / 255,
                     green: Double((number >> 8) & 255) / 255,
                     blue: Double(number & 255) / 255, opacity: 1)
    }

    var primary: Color { Self.color(palette.primary, fallback: .blue) }
    var secondary: Color { Self.color(palette.secondary, fallback: .teal) }
    var accent: Color { Self.color(palette.accent, fallback: .accentColor) }
    var selection: Color { Self.color(palette.selection, fallback: .accentColor) }
}
