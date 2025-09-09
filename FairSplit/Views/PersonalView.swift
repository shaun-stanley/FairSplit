import SwiftUI

struct PersonalView: View {
    @State private var showingAdd = false
    @State private var showingAccount = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ContentUnavailableView {
                        Label("No Personal Expenses", systemImage: "creditcard")
                    } description: {
                        Text("Add your own expenses to track and review.")
                    } actions: {
                        Button {
                            showingAdd = true
                        } label: {
                            Label("Add Expense", systemImage: "plus")
                        }
                    }
                }
                .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
            }
            .listStyle(.insetGrouped)
            .listSectionSpacing(.compact)
            .contentMargins(.horizontal, 20, for: .scrollContent)
            .contentMargins(.top, 4, for: .scrollContent)
            .navigationTitle("Personal")
            .toolbarTitleDisplayMode(.inlineLarge)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { showingAccount = true } label: { Image(systemName: "person.crop.circle") }
                        .accessibilityLabel("Account")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingAdd = true } label: { Image(systemName: "plus") }
                        .accessibilityLabel("Add Expense")
                }
            }
        }
        .sheet(isPresented: $showingAccount) { AccountView() }
        // Placeholder add flow (implemented in later steps of the epic)
        .sheet(isPresented: $showingAdd) {
            NavigationStack {
                Form {
                    Text("Coming soon")
                        .foregroundStyle(.secondary)
                }
                .navigationTitle("New Personal Expense")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Close") { showingAdd = false } }
                }
            }
        }
    }
}

#Preview {
    PersonalView()
}

