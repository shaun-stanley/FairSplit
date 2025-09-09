import SwiftUI

struct AccountView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("Account") {
                    // Placeholder for profile; can be expanded later
                    HStack(spacing: 12) {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Your Account")
                                .font(.headline)
                            Text("Manage settings and data")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
                Section("App") {
                    NavigationLink(destination: SettingsView(showsClose: false)) {
                        Label("Settings", systemImage: "gearshape")
                    }
                }
            }
            .contentMargins(.horizontal, 20, for: .scrollContent)
            .contentMargins(.top, 4, for: .scrollContent)
            .navigationTitle("Account")
            .toolbarTitleDisplayMode(.inlineLarge)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } }
            }
        }
    }
}

#Preview {
    AccountView()
}

