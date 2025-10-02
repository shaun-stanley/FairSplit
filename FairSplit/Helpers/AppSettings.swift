import SwiftUI

enum AppSettings {
    static let accentKey = "app_accent"
    static let appearanceKey = "app_appearance"
    static let welcomeCompletedKey = "welcome_completed"
    static let cloudSyncKey = "cloud_sync_enabled"
    static let cloudSyncStatusKey = "cloud_sync.status"
    static let cloudSyncStatusMessageKey = "cloud_sync.statusMessage"
    static let notificationsEnabledKey = "notifications_enabled"
    static let notificationsHourKey = "notifications_hour"
    static let notificationsMinuteKey = "notifications_minute"
    static let defaultCurrencyKey = "default_currency_code"
    static let diagnosticsEnabledKey = "diagnostics_enabled"
    static let cloudKitContainerIdentifier = "iCloud.com.sviftstudios.FairSplit"

    static let accentPresets: [(id: String, color: Color)] = [
        ("blue", .blue), ("green", .green), ("teal", .teal), ("indigo", .indigo),
        ("purple", .purple), ("pink", .pink), ("orange", .orange), ("red", .red)
    ]

    static func color(for id: String) -> Color {
        accentPresets.first(where: { $0.id == id })?.color ?? .accentColor
    }

    /// appearance: "system" | "light" | "dark"
    static func scheme(for appearance: String) -> ColorScheme? {
        switch appearance {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }

    static func defaultCurrencyCode() -> String {
        if let saved = UserDefaults.standard.string(forKey: defaultCurrencyKey), !saved.isEmpty { return saved }
        if let code = Locale.current.currency?.identifier { return code }
        return "USD"
    }

    static let currencyPresets: [String] = [
        "INR", "USD", "EUR", "GBP", "JPY", "AUD", "CAD", "CNY", "SGD", "AED"
    ]
}
