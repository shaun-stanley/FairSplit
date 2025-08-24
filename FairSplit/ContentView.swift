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

    var body: some View {
        NavigationStack {
            GroupListView()
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
