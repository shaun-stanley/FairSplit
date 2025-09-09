import SwiftUI
import SwiftData

struct GroupListView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Query(sort: [SortDescriptor(\Group.name)]) private var groups: [Group]
    @Environment(\.modelContext) private var modelContext
    @Environment(\.undoManager) private var undoManager
    @AppStorage(AppSettings.defaultCurrencyKey) private var defaultCurrency: String = AppSettings.defaultCurrencyCode()
    @State private var searchText = ""
    @State private var showingAdd = false
    @State private var showingAccount = false
    @State private var isRefreshing = false

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
            if !activeGroups.isEmpty { activeSection }
            if !archivedGroups.isEmpty { archivedSection }
        }
        .listStyle(.insetGrouped)
        .listSectionSpacing(.compact)
        // Align large titles with content like Apple apps
        .contentMargins(.horizontal, 20, for: .scrollContent)
        .contentMargins(.top, 4, for: .scrollContent)
        .redacted(reason: isRefreshing ? .placeholder : [])
        .refreshable {
            isRefreshing = true
            try? await Task.sleep(nanoseconds: 800_000_000)
            isRefreshing = false
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
        .toolbarTitleDisplayMode(.inlineLarge)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(action: { showingAccount = true }) { Image(systemName: "person.crop.circle") }
                    .accessibilityLabel("Account")
            }
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
        .sheet(isPresented: $showingAccount) { AccountView() }
        .sheet(isPresented: $showingAdd) {
            AddGroupView { name in
                if reduceMotion {
                    DataRepository(context: modelContext, undoManager: undoManager)
                        .addGroup(name: name, defaultCurrency: defaultCurrency)
                } else {
                    withAnimation(AppAnimations.spring) {
                        DataRepository(context: modelContext, undoManager: undoManager)
                            .addGroup(name: name, defaultCurrency: defaultCurrency)
                    }
                }
                searchText = ""
            }
        }
    }
}

private extension GroupListView {
    @ViewBuilder
    var activeSection: some View {
        Section("Active") {
            // Delightful, large horizontally scrollable tiles inspired by Apple Music
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(activeGroups, id: \.persistentModelID) { group in
                        NavigationLink(destination: GroupDetailView(group: group)) {
                            groupTile(group)
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            Button("Archive") {
                                if reduceMotion {
                                    DataRepository(context: modelContext, undoManager: undoManager)
                                        .setArchived(true, for: group)
                                } else {
                                    withAnimation(AppAnimations.spring) {
                                        DataRepository(context: modelContext, undoManager: undoManager)
                                            .setArchived(true, for: group)
                                    }
                                }
                                Haptics.success()
                            }
                        }
                    }
                }
                .padding(.horizontal, 4) // breathing room at the edges
                .padding(.vertical, 2)
            }
            .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 8, trailing: 0))
            .listRowBackground(Color.clear)
        }
    }

    @ViewBuilder
    var archivedSection: some View {
        Section("Archived") {
            ForEach(archivedGroups, id: \.persistentModelID) { group in
                NavigationLink(destination: GroupDetailView(group: group)) {
                    groupRow(group)
                }
                .badge("Archived")
                .swipeActions(allowsFullSwipe: true) {
                    Button("Unarchive") {
                        if reduceMotion {
                            DataRepository(context: modelContext, undoManager: undoManager)
                                .setArchived(false, for: group)
                        } else {
                            withAnimation(AppAnimations.spring) {
                                DataRepository(context: modelContext, undoManager: undoManager)
                                    .setArchived(false, for: group)
                            }
                        }
                        Haptics.success()
                    }.tint(.green)
                }
            }
        }
    }
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

    // Large tile used in the horizontal carousel
    @ViewBuilder
    func groupTile(_ group: Group) -> some View {
        let (start, end) = tileGradientColors(for: group)
        let width: CGFloat = 300
        let height: CGFloat = 180
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(LinearGradient(gradient: Gradient(colors: [start, end]), startPoint: .topLeading, endPoint: .bottomTrailing))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.08))
                )
            VStack(alignment: .leading, spacing: 8) {
                Text(group.name)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .shadow(color: .black.opacity(0.25), radius: 2, x: 0, y: 1)
                if let me = group.members.first {
                    let balance = group.balance(for: me)
                    let subtitle: String = {
                        if balance > 0 {
                            return "You're owed \(CurrencyFormatter.string(from: balance, currencyCode: group.defaultCurrency))"
                        } else if balance < 0 {
                            return "You owe \(CurrencyFormatter.string(from: -balance, currencyCode: group.defaultCurrency))"
                        } else {
                            return "All settled"
                        }
                    }()
                    Text(subtitle)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.95))
                        .shadow(color: .black.opacity(0.25), radius: 2, x: 0, y: 1)
                }
            }
            .padding(16)
        }
        .frame(width: width, height: height)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(groupAccessibilityLabel(group))
        .accessibilityHint("Opens group details")
    }

    // Deterministic pleasant gradient based on the group name
    func tileGradientColors(for group: Group) -> (Color, Color) {
        let name = group.name
        var hasher = Hasher()
        hasher.combine(name)
        let value = UInt64(bitPattern: Int64(hasher.finalize()))
        // Map hash to hues for two related colors
        let hue1 = Double((value % 360)) / 360.0
        let hue2 = Double(((value >> 8) % 360)) / 360.0
        let c1 = Color(hue: hue1, saturation: 0.75, brightness: 0.85)
        let c2 = Color(hue: (hue1 * 0.6 + hue2 * 0.4).truncatingRemainder(dividingBy: 1.0), saturation: 0.85, brightness: 0.75)
        return (c1, c2)
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
