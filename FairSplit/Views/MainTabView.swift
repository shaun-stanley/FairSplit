import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            RootView()
                .tabItem {
                    Label("Groups", systemImage: "person.3")
                }

            DirectListView()
                .tabItem {
                    Label("Direct", systemImage: "arrow.left.arrow.right")
                }

            PersonalView()
                .tabItem {
                    Label("Personal", systemImage: "creditcard")
                }

            ReportsView()
                .tabItem {
                    Label("Reports", systemImage: "chart.bar")
                }
        }
    }
}

#Preview {
    MainTabView()
        .modelContainer(for: [Group.self, Member.self, Expense.self, Settlement.self, Comment.self, PersonalExpense.self], inMemory: true)
}
