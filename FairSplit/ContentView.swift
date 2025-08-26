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
    @AppStorage(AppSettings.accentKey) private var accentID: String = "blue"
    @AppStorage(AppSettings.appearanceKey) private var appearance: String = "system"

    var body: some View {
        RootView()
        .task {
            DataRepository(context: modelContext).seedIfNeeded()
        }
        .preferredColorScheme(AppSettings.scheme(for: appearance))
        .tint(AppSettings.color(for: accentID))
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Group.self, Member.self, Expense.self, Settlement.self], inMemory: true)
}
