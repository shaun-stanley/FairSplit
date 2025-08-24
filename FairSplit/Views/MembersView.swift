import SwiftUI
import SwiftData

struct MembersView: View {
    @Environment(\.modelContext) private var modelContext
    let group: Group

    @State private var showingAdd = false
    @State private var newName = ""
    @State private var renaming: Member?
    @State private var renameText = ""
    @State private var alertMessage: String?

    var body: some View {
        List {
            ForEach(group.members, id: \.persistentModelID) { member in
                Text(member.name)
                    .swipeActions {
                        Button("Rename") {
                            renaming = member
                            renameText = member.name
                        }.tint(.blue)
                        Button("Delete", role: .destructive) {
                            let ok = DataRepository(context: modelContext).delete(member: member, from: group)
                            if !ok { alertMessage = "This member is used in expenses and cannot be deleted." }
                        }
                    }
            }
        }
        .navigationTitle("Members")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Add") { showingAdd = true }
            }
        }
        .sheet(isPresented: $showingAdd) {
            NavigationStack {
                Form { TextField("Name", text: $newName) }
                .navigationTitle("New Member")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Cancel") { showingAdd = false; newName = "" } }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
                            guard !trimmed.isEmpty else { return }
                            DataRepository(context: modelContext).addMember(to: group, name: trimmed)
                            showingAdd = false
                            newName = ""
                        }.disabled(newName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
            }
        }
        .sheet(item: $renaming) { member in
            NavigationStack {
                Form { TextField("Name", text: $renameText) }
                .navigationTitle("Rename Member")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Cancel") { renaming = nil } }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            let trimmed = renameText.trimmingCharacters(in: .whitespacesAndNewlines)
                            guard !trimmed.isEmpty else { return }
                            DataRepository(context: modelContext).rename(member: member, to: trimmed)
                            renaming = nil
                        }.disabled(renameText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
            }
        }
        .alert("Cannot Delete Member", isPresented: Binding(get: { alertMessage != nil }, set: { if !$0 { alertMessage = nil } })) {
            Button("OK", role: .cancel) { alertMessage = nil }
        } message: {
            Text(alertMessage ?? "")
        }
    }
}

#Preview {
    let m1 = Member(name: "Alex")
    let group = Group(name: "Trip", defaultCurrency: "USD", members: [m1])
    return NavigationStack { MembersView(group: group) }
}
