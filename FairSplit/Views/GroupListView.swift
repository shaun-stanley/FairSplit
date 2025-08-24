import SwiftUI
import SwiftData

struct GroupListView: View {
    @Query private var groups: [Group]
    @State private var searchText = ""

    private var filteredGroups: [Group] {
        let filtered = groups.filter { searchText.isEmpty || $0.name.localizedCaseInsensitiveContains(searchText) }
        return filtered.sorted { $0.lastActivity > $1.lastActivity }
    }

    var body: some View {
        List(filteredGroups) { group in
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
    }
}

#Preview {
    GroupListView()
        .modelContainer(for: [Group.self, Member.self, Expense.self, Settlement.self], inMemory: true)
}
