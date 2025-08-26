//
//  ContentView.swift
//  FairSplit
//
//  Created by Shaun Stanley on 8/24/25.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\Group.lastActivity, order: .reverse)]) private var groups: [Group]
    @AppStorage(AppSettings.accentKey) private var accentID: String = "blue"
    @AppStorage(AppSettings.appearanceKey) private var appearance: String = "system"
    @State private var showQuickAdd = false
    @State private var quickAddGroup: Group?
    @State private var showGroup = false
    @State private var openGroup: Group?

    var body: some View {
        MainTabView()
        .task {
            let repo = DataRepository(context: modelContext)
            repo.seedIfNeeded()
            repo.generateDueRecurring()
            NotificationsManager.refreshFromSettings()
        }
        .onOpenURL { url in
            guard url.scheme?.lowercased() == "fairsplit" else { return }
            switch url.host?.lowercased() {
            case "add-expense":
                // Choose the most recent active group
                if let group = groups.first(where: { !$0.isArchived }) ?? groups.first {
                    quickAddGroup = group
                    showQuickAdd = true
                }
            case "group":
                if let comps = URLComponents(url: url, resolvingAgainstBaseURL: false),
                   let name = comps.queryItems?.first(where: { $0.name == "name" })?.value {
                    if let group = groups.first(where: { $0.name.localizedCaseInsensitiveContains(name) }) {
                        openGroup = group
                        showGroup = true
                    }
                } else if let group = groups.first {
                    openGroup = group
                    showGroup = true
                }
            default:
                break
            }
        }
        .preferredColorScheme(AppSettings.scheme(for: appearance))
        .tint(AppSettings.color(for: accentID))
        .sheet(isPresented: $showQuickAdd) {
            if let group = quickAddGroup {
                NavigationStack {
                    AddExpenseView(members: group.members, groupCurrencyCode: group.defaultCurrency, lastRates: group.lastFXRates) { title, amount, currency, rate, payer, participants, category, note, receipt in
                        DataRepository(context: modelContext).addExpense(to: group, title: title, amount: amount, payer: payer, participants: participants, category: category, note: note, receiptImageData: receipt, currencyCode: currency, fxRateToGroupCurrency: rate)
                        showQuickAdd = false
                        quickAddGroup = nil
                    }
                }
            }
        }
        .sheet(isPresented: $showGroup) {
            if let group = openGroup {
                NavigationStack { GroupDetailView(group: group) }
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Group.self, Member.self, Expense.self, Settlement.self, RecurringExpense.self, Contact.self, DirectExpense.self, Comment.self], inMemory: true)
}
