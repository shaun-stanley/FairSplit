import SwiftUI

struct SettingsView: View {
    @AppStorage(AppSettings.accentKey) private var accentID: String = "blue"
    @AppStorage(AppSettings.appearanceKey) private var appearance: String = "system"
    @AppStorage(AppSettings.cloudSyncKey) private var cloudSync: Bool = false
    @Environment(\.dismiss) private var dismiss

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
