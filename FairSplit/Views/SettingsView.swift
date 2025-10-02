import SwiftUI

struct SettingsView: View {
    var showsClose: Bool = true
    @AppStorage(AppSettings.accentKey) private var accentID: String = "blue"
    @AppStorage(AppSettings.appearanceKey) private var appearance: String = "system"
    @AppStorage(AppSettings.cloudSyncKey) private var cloudSync: Bool = false
    @AppStorage("privacy_lock_enabled") private var privacyLock: Bool = false
    @AppStorage(AppSettings.defaultCurrencyKey) private var defaultCurrency: String = AppSettings.defaultCurrencyCode()
    @AppStorage(AppSettings.diagnosticsEnabledKey) private var diagnosticsEnabled: Bool = false
    @AppStorage(WidgetDataWriter.availabilityKey) private var widgetAppGroupAvailable: Bool = true
    @AppStorage(AppSettings.cloudSyncStatusKey) private var cloudSyncStatusRaw: String = CloudSyncStatus.unknown.rawValue
    @AppStorage(AppSettings.cloudSyncStatusMessageKey) private var cloudSyncStatusMessage: String = ""
    @Environment(\.dismiss) private var dismiss
    @State private var showingShare = false
    @State private var exportURL: URL?
    @State private var showCloudSyncAlert = false
    @State private var cloudSyncAlertMessage: String = ""
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
                Section("Currency") {
                    Picker("Default Currency", selection: $defaultCurrency) {
                        ForEach(AppSettings.currencyPresets, id: \.self) { code in
                            HStack {
                                Text(Locale.current.localizedString(forCurrencyCode: code) ?? code)
                                Spacer()
                                Text(code).foregroundStyle(.secondary)
                            }.tag(code)
                        }
                    }
                    Text("Used for new groups and formatting.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                if !widgetAppGroupAvailable {
                    Section("Widgets") {
                        Label {
                            Text("Widget data can’t refresh in this build.")
                                .font(.callout)
                        } icon: {
                            Image(systemName: "rectangle.on.rectangle.slash")
                                .foregroundStyle(.secondary)
                        }
                        Text("Enable the shared App Group entitlement or install the App Store build to let the FairSplit widget stay updated.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                Section("Privacy") {
                    Toggle(isOn: $privacyLock) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Privacy Lock")
                            Text("Require Face ID/Touch ID to view the app.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                Section("Diagnostics") {
                    Toggle(isOn: $diagnosticsEnabled) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Diagnostics Logs")
                            Text("Writes non-sensitive events to the system log and an in-app log for export.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Button("Export Logs…") {
                        let text = DiagnosticsLog.shared.exportText()
                        let data = text.data(using: .utf8) ?? Data()
                        if let url = try? TempFileWriter.writeTemporary(data: data, fileName: "FairSplit-Diagnostics-\(Int(Date().timeIntervalSince1970))", fileExtension: "txt") {
                            // Present share sheet by flipping a binding via local state
                            exportURL = url
                            showingShare = true
                        }
                    }
                }
                Section("Sync") {
                    Toggle(isOn: Binding(get: {
                        cloudSync
                    }, set: { newValue in
                        cloudSync = newValue
                        if newValue {
                            CloudSyncStatusChecker.refresh()
                            cloudSyncAlertMessage = "Restart FairSplit after enabling sync so it can connect to iCloud."
                            showCloudSyncAlert = true
                        } else {
                            CloudSyncStatusReporter.update(.unknown)
                        }
                    })) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Sync with iCloud")
                            Text("Keeps data updated across devices. Requires iCloud & may need a restart.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                    if let statusMessage = friendlyCloudSyncStatusDescription {
                        Label {
                            Text(statusMessage)
                                .font(.callout)
                        } icon: {
                            Image(systemName: "icloud.slash")
                                .symbolRenderingMode(.hierarchical)
                                .foregroundStyle(.secondary)
                        }
                        .accessibilityHint("Cloud sync status")
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
            .toolbarTitleDisplayMode(.inlineLarge)
            .contentMargins(.horizontal, 20, for: .scrollContent)
            .contentMargins(.top, 4, for: .scrollContent)
            .toolbar {
                if showsClose {
                    ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } }
                }
            }
            .sheet(isPresented: $showingShare) {
                if let url = exportURL {
                    ShareSheet(activityItems: [url])
                }
            }
            .alert("iCloud Sync", isPresented: $showCloudSyncAlert, actions: {
                Button("OK", role: .cancel) {}
            }, message: {
                Text(cloudSyncAlertMessage)
            })
        }
    }
}

private extension SettingsView {
    var cloudSyncStatus: CloudSyncStatus {
        CloudSyncStatus(rawValue: cloudSyncStatusRaw) ?? .unknown
    }

    var friendlyCloudSyncStatusDescription: String? {
        switch cloudSyncStatus {
        case .unknown:
            return cloudSync ? "Sync will start after you restart FairSplit." : nil
        case .available:
            return nil
        case .missingEntitlement:
            return "This build is missing the CloudKit entitlement. Use an iCloud-signed build to sync."
        case .accountUnavailable:
            return "Sign in to iCloud on this device to enable syncing."
        case .error:
            let trimmed = cloudSyncStatusMessage.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? "Sync is temporarily unavailable." : trimmed
        }
    }
}

#Preview {
    SettingsView()
}
