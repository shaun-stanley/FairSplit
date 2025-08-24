//
//  ContentView.swift
//  FairSplit
//
//  Created by Shaun Stanley on 8/24/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor<Group>(\Group.name)]) private var groups: [Group]

    // Provide an explicit initializer to avoid memberwise init that expects 'groups' parameter
    init(groups _: [Group] = []) {}

    var body: some View {
        let group = groups.first
        TabView {
            NavigationStack {
                if let group { ExpenseListView(group: group) }
                else { Text("Seeding data...") }
            }
            .tabItem { Label("Expenses", systemImage: "list.bullet") }

            NavigationStack {
                if let group { SplitSummaryView(group: group) }
                else { Text("Seeding data...") }
            }
            .tabItem { Label("Summary", systemImage: "person.3.sequence") }
        }
        .task {
            DataRepository(context: modelContext).seedIfNeeded()
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Group.self, Member.self, Expense.self], inMemory: true)
}
