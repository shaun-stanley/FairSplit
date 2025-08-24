import SwiftUI
import SwiftData

struct GroupDetailView: View {
    let group: Group

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, pinnedViews: [.sectionHeaders]) {
                Section(
                    header: Text("Expenses")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.background)
                ) {
                    ExpenseListView(group: group)
                }

                Section(
                    header: Text("Balances")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.background)
                ) {
                    SplitSummaryView(group: group)
                }

                Section(
                    header: Text("Settle Up")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.background)
                ) {
                    SettleUpView(group: group)
                }

                Section(
                    header: Text("Members")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.background)
                ) {
                    ForEach(group.members, id: \.persistentModelID) { member in
                        Text(member.name)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 4)
                    }
                }
            }
            .padding(.horizontal)
        }
        .navigationTitle(group.name)
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
