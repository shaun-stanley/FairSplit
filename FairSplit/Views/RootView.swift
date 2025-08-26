import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(\.horizontalSizeClass) private var sizeClass

    var body: some View {
        if sizeClass == .regular {
            SplitRootView()
        } else {
            NavigationStack { GroupListView() }
        }
    }
}

private struct SplitRootView: View {
    @Query(sort: [SortDescriptor(\Group.name)]) private var groups: [Group]
    @Environment(\.modelContext) private var modelContext
    @Environment(\.undoManager) private var undoManager
    @State private var selected: Group?
    @State private var showingAdd = false
    @State private var showingSettings = false
    @State private var searchText = ""

    private var filtered: [Group] {
        let f = groups.filter { searchText.isEmpty || $0.name.localizedCaseInsensitiveContains(searchText) }
        return f.sorted { $0.lastActivity > $1.lastActivity }
    }

    var body: some View {
        NavigationSplitView {
            List(filtered, selection: $selected) { group in
                VStack(alignment: .leading) {
                    Text(group.name)
                    Text("Last activity: \(group.lastActivity.formatted(date: .abbreviated, time: .omitted))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Groups")
            .searchable(text: $searchText)
            .toolbar {
                ToolbarItemGroup(placement: .primaryAction) {
                    Button(action: { showingSettings = true }) { Image(systemName: "gearshape") }
                        .accessibilityLabel("Settings")
                    Button(action: { showingAdd = true }) { Image(systemName: "plus") }
                        .accessibilityLabel("Add Group")
                        .keyboardShortcut("n", modifiers: [.command])
                }
            }
        } detail: {
            if let group = selected {
                GroupDetailView(group: group)
            } else {
                ContentUnavailableView("Select a group", systemImage: "person.3")
            }
        }
        .sheet(isPresented: $showingAdd) {
            AddGroupView { name in
                withAnimation {
                    DataRepository(context: modelContext, undoManager: undoManager).addGroup(name: name, defaultCurrency: "INR")
                }
            }
        }
        .sheet(isPresented: $showingSettings) { SettingsView() }
    }
}

#Preview {
    RootView()
        .modelContainer(for: [Group.self, Member.self, Expense.self, Settlement.self], inMemory: true)
}

