import SwiftUI

enum AppSettings {
    static let accentKey = "app_accent"
    static let appearanceKey = "app_appearance"
    static let cloudSyncKey = "cloud_sync_enabled"

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
}
