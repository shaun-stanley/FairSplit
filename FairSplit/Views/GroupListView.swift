import SwiftUI
import SwiftData

struct GroupListView: View {
    @Query(sort: [SortDescriptor(\Group.name)]) private var groups: [Group]
    @Environment(\.modelContext) private var modelContext
    @Environment(\.undoManager) private var undoManager
    @State private var searchText = ""
    @State private var showingAdd = false

    private var filteredGroups: [Group] {
        let filtered = groups.filter { searchText.isEmpty || $0.name.localizedCaseInsensitiveContains(searchText) }
        return filtered.sorted { $0.lastActivity > $1.lastActivity }
    }

    var body: some View {
        List(filteredGroups, id: \.persistentModelID) { group in
            NavigationLink(destination: GroupDetailView(group: group)) {
                VStack(alignment: .leading) {
                    Text(group.name)
                    if let me = group.members.first {
                        let balance = group.balance(for: me)
                        if balance > 0 {
                            Text("You're owed \(balance.formatted(.currency(code: group.defaultCurrency)))")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        } else if balance < 0 {
                            Text("You owe \((-balance).formatted(.currency(code: group.defaultCurrency)))")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        } else {
                            Text("All settled")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .searchable(text: $searchText)
        .navigationTitle("Groups")
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button(action: { showingAdd = true }) {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Add Group")
            }
        }
        .sheet(isPresented: $showingAdd) {
            AddGroupView { name in
                withAnimation {
                    DataRepository(context: modelContext, undoManager: undoManager)
                        .addGroup(name: name, defaultCurrency: "INR")
                }
                searchText = ""
            }
        }
    }
}

#Preview {
    GroupListView()
        .modelContainer(for: [Group.self, Member.self, Expense.self, Settlement.self], inMemory: true)
}
