import SwiftUI
import SwiftData

struct GroupListView: View {
    @Query(sort: [SortDescriptor(\Group.name)]) private var groups: [Group]
    @Environment(\.modelContext) private var modelContext
    @Environment(\.undoManager) private var undoManager
    @AppStorage(AppSettings.defaultCurrencyKey) private var defaultCurrency: String = AppSettings.defaultCurrencyCode()
    @State private var searchText = ""
    @State private var showingAdd = false

    private var activeGroups: [Group] {
        groups.filter { !$0.isArchived && (searchText.isEmpty || $0.name.localizedCaseInsensitiveContains(searchText)) }
            .sorted { $0.lastActivity > $1.lastActivity }
    }
    private var archivedGroups: [Group] {
        groups.filter { $0.isArchived && (searchText.isEmpty || $0.name.localizedCaseInsensitiveContains(searchText)) }
            .sorted { ($0.archivedAt ?? .distantPast) > ($1.archivedAt ?? .distantPast) }
    }

    var body: some View {
        List {
            if !activeGroups.isEmpty {
                Section("Active") {
                    ForEach(activeGroups, id: \.persistentModelID) { group in
                        NavigationLink(destination: GroupDetailView(group: group)) {
                            groupRow(group)
                        }
                        .swipeActions(allowsFullSwipe: true) {
                            Button("Archive") {
                                DataRepository(context: modelContext, undoManager: undoManager)
                                    .setArchived(true, for: group)
                                Haptics.success()
                            }.tint(.orange)
                        }
                    }
                }
            }
            if !archivedGroups.isEmpty {
                Section("Archived") {
                    ForEach(archivedGroups, id: \.persistentModelID) { group in
                        NavigationLink(destination: GroupDetailView(group: group)) {
                            groupRow(group)
                        }
                        .badge("Archived")
                        .swipeActions(allowsFullSwipe: true) {
                            Button("Unarchive") {
                                DataRepository(context: modelContext, undoManager: undoManager)
                                    .setArchived(false, for: group)
                                Haptics.success()
                            }.tint(.green)
                        }
                    }
                }
            }
        }
        .overlay {
            if activeGroups.isEmpty && archivedGroups.isEmpty {
                ContentUnavailableView {
                    Label("No Groups", systemImage: "person.3")
                } description: {
                    Text("Add a group to get started.")
                } actions: {
                    Button {
                        showingAdd = true
                    } label: {
                        Label("Add Group", systemImage: "plus")
                    }
                }
            }
        }
        .searchable(text: $searchText)
        .navigationTitle("Groups")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button(action: { showingAdd = true }) {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Add Group")
                #if canImport(TipKit)
                .popoverTip(AppTips.addGroup)
                #endif
            }
        }
        .sheet(isPresented: $showingAdd) {
            AddGroupView { name in
                withAnimation {
                    DataRepository(context: modelContext, undoManager: undoManager)
                        .addGroup(name: name, defaultCurrency: defaultCurrency)
                }
                searchText = ""
            }
        }
    }
}

private extension GroupListView {
    @ViewBuilder
    func groupRow(_ group: Group) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(group.name)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
            if let me = group.members.first {
                let balance = group.balance(for: me)
                if balance > 0 {
                    Text("You're owed \(CurrencyFormatter.string(from: balance, currencyCode: group.defaultCurrency))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                } else if balance < 0 {
                    Text("You owe \(CurrencyFormatter.string(from: -balance, currencyCode: group.defaultCurrency))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                } else {
                    Text("All settled")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(groupAccessibilityLabel(group))
        .accessibilityHint("Opens group details")
    }
    func groupAccessibilityLabel(_ group: Group) -> String {
        var parts: [String] = [group.name]
        if let first = group.members.first {
            let bal = group.balance(for: first)
            if bal > 0 {
                parts.append("You're owed \(CurrencyFormatter.string(from: bal, currencyCode: group.defaultCurrency))")
            } else if bal < 0 {
                parts.append("You owe \(CurrencyFormatter.string(from: -bal, currencyCode: group.defaultCurrency))")
            } else {
                parts.append("All settled")
            }
        }
        return parts.joined(separator: ", ")
    }
}

#Preview {
    GroupListView()
        .modelContainer(for: [Group.self, Member.self, Expense.self, Settlement.self, RecurringExpense.self, Comment.self], inMemory: true)
}
