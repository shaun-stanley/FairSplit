import SwiftUI
import SwiftData

struct GroupDetailView: View {
    let group: Group

    var body: some View {
        TabView {
            ExpenseListView(group: group)
                .tabItem { Label("Expenses", systemImage: "list.bullet") }
            SplitSummaryView(group: group)
                .tabItem { Label("Summary", systemImage: "person.3.sequence") }
        }
    }
}

#Preview {
    if let container = try? ModelContainer(
        for: Group.self, Member.self, Expense.self, Settlement.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    ) {
        let member = Member(name: "A")
        let group = Group(name: "G", defaultCurrency: "USD", members: [member])
        return GroupDetailView(group: group).modelContainer(container)
    } else {
        return Text("Preview unavailable")
    }
}
