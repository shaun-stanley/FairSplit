import SwiftUI
import SwiftData

struct MembersView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.modelContext) private var modelContext
    @Environment(\.undoManager) private var undoManager
    let group: Group

    @State private var showingAdd = false
    @State private var newName = ""
    @State private var renaming: Member?
    @State private var renameText = ""
    @State private var alertMessage: String?
    @State private var mergingSource: Member?
    @State private var mergingTarget: Member?
    #if canImport(ContactsUI)
    @State private var showingContacts = false
    #endif

    var body: some View {
        List {
            ForEach(group.members, id: \.persistentModelID) { member in
                Text(member.name)
                    .swipeActions {
                        Button("Rename") {
                            renaming = member
                            renameText = member.name
                        }.tint(.blue)
                        Button("Merge Into…") {
                            mergingSource = member
                            mergingTarget = group.members.first { $0.persistentModelID != member.persistentModelID }
                        }.tint(.purple)
                        Button("Delete", role: .destructive) {
                            let ok: Bool
                            if reduceMotion {
                                ok = DataRepository(context: modelContext, undoManager: undoManager).delete(member: member, from: group)
                            } else {
                                ok = withAnimation(AppAnimations.spring) {
                                    DataRepository(context: modelContext, undoManager: undoManager).delete(member: member, from: group)
                                }
                            }
                            if !ok { alertMessage = "This member is used in expenses and cannot be deleted." }
                        }
                    }
            }
        }
        .contentMargins(.horizontal, 20, for: .scrollContent)
        .navigationTitle("Members")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button("New Member") { showingAdd = true }
                    #if canImport(ContactsUI)
                    Button("From Contacts…") { showingContacts = true }
                    #endif
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Add Member")
                #if canImport(TipKit)
                .popoverTip(AppTips.addMember)
                #endif
            }
        }
        .sheet(isPresented: $showingAdd) {
            NavigationStack {
                Form { TextField("Name", text: $newName) }
                .contentMargins(.horizontal, 20, for: .scrollContent)
                .navigationTitle("New Member")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Cancel") { showingAdd = false; newName = "" } }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
                            guard !trimmed.isEmpty else { return }
                            if reduceMotion {
                                DataRepository(context: modelContext, undoManager: undoManager).addMember(to: group, name: trimmed)
                            } else {
                                withAnimation(AppAnimations.spring) {
                                    DataRepository(context: modelContext, undoManager: undoManager).addMember(to: group, name: trimmed)
                                }
                            }
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
                .contentMargins(.horizontal, 20, for: .scrollContent)
                .navigationTitle("Rename Member")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Cancel") { renaming = nil } }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            let trimmed = renameText.trimmingCharacters(in: .whitespacesAndNewlines)
                            guard !trimmed.isEmpty else { return }
                            if reduceMotion {
                                DataRepository(context: modelContext, undoManager: undoManager).rename(member: member, to: trimmed)
                            } else {
                                withAnimation(AppAnimations.spring) {
                                    DataRepository(context: modelContext, undoManager: undoManager).rename(member: member, to: trimmed)
                                }
                            }
                            renaming = nil
                        }.disabled(renameText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
            }
        }
        .sheet(item: $mergingSource) { source in
            NavigationStack {
                Form {
                    Picker("Merge \(source.name) into", selection: Binding(
                        get: { mergingTarget },
                        set: { mergingTarget = $0 }
                    )) {
                        ForEach(group.members.filter { $0.persistentModelID != source.persistentModelID }, id: \.persistentModelID) { m in
                            Text(m.name).tag(m as Member?)
                        }
                    }
                    .pickerStyle(.navigationLink)
                }
                .contentMargins(.horizontal, 20, for: .scrollContent)
                .navigationTitle("Merge Members")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Cancel") { mergingSource = nil; mergingTarget = nil } }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Merge") {
                            if let target = mergingTarget {
                                if reduceMotion {
                                    DataRepository(context: modelContext, undoManager: undoManager).merge(member: source, into: target, in: group)
                                } else {
                                    withAnimation(AppAnimations.spring) {
                                        DataRepository(context: modelContext, undoManager: undoManager).merge(member: source, into: target, in: group)
                                    }
                                }
                            }
                            mergingSource = nil
                            mergingTarget = nil
                        }.disabled(mergingTarget == nil)
                    }
                }
            }
        }
        #if canImport(ContactsUI)
        .sheet(isPresented: $showingContacts) {
            ContactsPickerView { contacts in
                let existing = Set(group.members.map { $0.name.lowercased() })
                let repo = DataRepository(context: modelContext, undoManager: undoManager)
                for c in contacts {
                    let name = buildName(from: c)
                    if !name.isEmpty && !existing.contains(name.lowercased()) {
                        repo.addMember(to: group, name: name)
                    }
                }
                showingContacts = false
            } onCancel: {
                showingContacts = false
            }
        }
        #endif
        .alert("Cannot Delete Member", isPresented: Binding(get: { alertMessage != nil }, set: { if !$0 { alertMessage = nil } })) {
            Button("OK", role: .cancel) { alertMessage = nil }
        } message: {
            Text(alertMessage ?? "")
        }
    }
}

#if canImport(Contacts)
import Contacts
private func buildName(from contact: CNContact) -> String {
    let composed = "\(contact.givenName) \(contact.familyName)".trimmingCharacters(in: .whitespaces)
    if !composed.isEmpty { return composed }
    if !contact.nickname.isEmpty { return contact.nickname }
    if !contact.organizationName.isEmpty { return contact.organizationName }
    return ""
}
#endif

#Preview {
    let m1 = Member(name: "Alex")
    let group = Group(name: "Trip", defaultCurrency: "USD", members: [m1])
    return NavigationStack { MembersView(group: group) }
}
