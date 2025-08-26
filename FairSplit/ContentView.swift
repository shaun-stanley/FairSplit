//
//  ContentView.swift
//  FairSplit
//
//  Created by Shaun Stanley on 8/24/25.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers
import LocalAuthentication

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\Group.lastActivity, order: .reverse)]) private var groups: [Group]
    @AppStorage(AppSettings.accentKey) private var accentID: String = "blue"
    @AppStorage(AppSettings.appearanceKey) private var appearance: String = "system"
    @AppStorage("privacy_lock_enabled") private var privacyLockEnabled: Bool = false
    @State private var showQuickAdd = false
    @State private var quickAddGroup: Group?
    @State private var showGroup = false
    @State private var openGroup: Group?
    @State private var isLocked: Bool = false
    @State private var isAuthenticating: Bool = false

    var body: some View {
        MainTabView()
        .task {
            let repo = DataRepository(context: modelContext)
            repo.seedIfNeeded()
            repo.generateDueRecurring()
            NotificationsManager.refreshFromSettings()
            // Apply privacy lock on launch if enabled
            if privacyLockEnabled { lockAndAuthenticate() }
            // Index content for Spotlight
            SpotlightIndexer.reindexAll(context: modelContext)
            // Seed widget data (if App Group is enabled)
            WidgetDataWriter.updateTopGroupSummary(groups: groups)
        }
        .onChange(of: groups) { _, newValue in
            WidgetDataWriter.updateTopGroupSummary(groups: newValue)
        }
        .onChange(of: privacyLockEnabled) { _, newValue in
            if newValue { lockAndAuthenticate() } else { isLocked = false }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
            if privacyLockEnabled { isLocked = true }
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
        .overlay(privacyOverlay())
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

private extension ContentView {
    func lockAndAuthenticate() {
        isLocked = true
        authenticate()
    }

    func authenticate() {
        guard !isAuthenticating else { return }
        let ctx = LAContext()
        var error: NSError?
        if ctx.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) || ctx.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
            isAuthenticating = true
            ctx.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: "Unlock FairSplit") { success, _ in
                DispatchQueue.main.async {
                    self.isAuthenticating = false
                    self.isLocked = !success
                }
            }
        }
    }

    @ViewBuilder func privacyOverlay() -> some View {
        if isLocked {
            ZStack {
                Color(.systemBackground)
                    .ignoresSafeArea()
                VStack(spacing: 16) {
                    Image(systemName: "lock.fill").font(.largeTitle)
                    Text("Locked")
                        .font(.headline)
                    Button(action: authenticate) {
                        HStack { Image(systemName: "faceid"); Text("Unlock") }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isAuthenticating)
                }
                .padding()
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Group.self, Member.self, Expense.self, Settlement.self, RecurringExpense.self, Contact.self, DirectExpense.self, Comment.self], inMemory: true)
}
