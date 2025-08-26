import SwiftUI

struct SettingsView: View {
    @AppStorage(AppSettings.accentKey) private var accentID: String = "blue"
    @AppStorage(AppSettings.appearanceKey) private var appearance: String = "system"
    @AppStorage(AppSettings.cloudSyncKey) private var cloudSync: Bool = false
    @Environment(\.dismiss) private var dismiss
    @State private var reminderTime: Date = {
        var comps = DateComponents()
        let hour = UserDefaults.standard.object(forKey: AppSettings.notificationsHourKey) as? Int ?? 9
        let minute = UserDefaults.standard.object(forKey: AppSettings.notificationsMinuteKey) as? Int ?? 0
        comps.hour = hour
        comps.minute = minute
        return Calendar.current.date(from: comps) ?? Date()
    }()

    var body: some View {
        NavigationStack {
            Form {
                Section("Sync") {
                    Toggle(isOn: $cloudSync) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Sync with iCloud")
                            Text("Keeps data updated across devices. Requires iCloud & may need a restart.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                Section("Reminders") {
                    Toggle(isOn: Binding(get: {
                        UserDefaults.standard.bool(forKey: AppSettings.notificationsEnabledKey)
                    }, set: { newValue in
                        UserDefaults.standard.set(newValue, forKey: AppSettings.notificationsEnabledKey)
                        if newValue {
                            NotificationsManager.requestAuthorizationIfNeeded { granted in
                                if granted {
                                    let comps = Calendar.current.dateComponents([.hour, .minute], from: reminderTime)
                                    let h = comps.hour ?? 9
                                    let m = comps.minute ?? 0
                                    UserDefaults.standard.set(h, forKey: AppSettings.notificationsHourKey)
                                    UserDefaults.standard.set(m, forKey: AppSettings.notificationsMinuteKey)
                                    NotificationsManager.scheduleDailyReminder(hour: h, minute: m)
                                } else {
                                    UserDefaults.standard.set(false, forKey: AppSettings.notificationsEnabledKey)
                                }
                            }
                        } else {
                            NotificationsManager.cancelDailyReminder()
                        }
                    })) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Daily Reminder")
                            Text("A gentle nudge to settle or log recurring.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                    DatePicker("Time", selection: $reminderTime, displayedComponents: .hourAndMinute)
                        .onChange(of: reminderTime) { _, newValue in
                            let comps = Calendar.current.dateComponents([.hour, .minute], from: newValue)
                            let h = comps.hour ?? 9
                            let m = comps.minute ?? 0
                            UserDefaults.standard.set(h, forKey: AppSettings.notificationsHourKey)
                            UserDefaults.standard.set(m, forKey: AppSettings.notificationsMinuteKey)
                            if UserDefaults.standard.bool(forKey: AppSettings.notificationsEnabledKey) {
                                NotificationsManager.scheduleDailyReminder(hour: h, minute: m)
                            }
                        }
                }
                Section("Appearance") {
                    Picker("Mode", selection: $appearance) {
                        Text("System").tag("system")
                        Text("Light").tag("light")
                        Text("Dark").tag("dark")
                    }
                    .pickerStyle(.segmented)
                }
                Section("Accent Color") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4)) {
                        ForEach(AppSettings.accentPresets, id: \.id) { preset in
                            Button(action: { accentID = preset.id }) {
                                ZStack {
                                    Circle()
                                        .fill(preset.color)
                                        .frame(width: 32, height: 32)
                                    if accentID == preset.id {
                                        Image(systemName: "checkmark")
                                            .font(.caption)
                                            .foregroundStyle(.white)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(Text(preset.id.capitalized))
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } }
            }
        }
    }
}

#Preview {
    SettingsView()
}
