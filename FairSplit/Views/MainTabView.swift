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
                    Label("Direct", systemImage: "person.fill.and.arrow.right")
                }

            ReportsView()
                .tabItem {
                    Label("Reports", systemImage: "chart.bar")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
        }
    }
}

#Preview {
    MainTabView()
        .modelContainer(for: [Group.self, Member.self, Expense.self, Settlement.self], inMemory: true)
}
