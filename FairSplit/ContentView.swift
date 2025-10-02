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
    // Sort by a persisted field; compute lastActivity in-memory when needed
    @Query(sort: [SortDescriptor(\Group.createdAt, order: .reverse)]) private var groups: [Group]
    @AppStorage(AppSettings.accentKey) private var accentID: String = "blue"
    @AppStorage(AppSettings.appearanceKey) private var appearance: String = "system"
    @AppStorage(AppSettings.welcomeCompletedKey) private var welcomeCompleted: Bool = false
    @AppStorage("privacy_lock_enabled") private var privacyLockEnabled: Bool = false
    @AppStorage(AppSettings.cloudSyncKey) private var cloudSyncEnabled: Bool = false
    @AppStorage(WidgetDataWriter.availabilityKey) private var widgetAppGroupAvailable: Bool = true
    @AppStorage(AppSettings.cloudSyncStatusKey) private var cloudSyncStatusRaw: String = CloudSyncStatus.unknown.rawValue
    @AppStorage(AppSettings.cloudSyncStatusMessageKey) private var cloudSyncStatusMessage: String = ""
    @State private var showQuickAdd = false
    @State private var quickAddGroup: Group?
    @State private var showGroup = false
    @State private var openGroup: Group?
    @State private var isLocked: Bool = false
    @State private var isAuthenticating: Bool = false

    @State private var showWelcome: Bool = false
    @State private var hasShownWidgetWarning = false
    @State private var hasShownCloudWarning = false
    @State private var activeSystemAlert: SystemAlert?
    @State private var alertQueue: [SystemAlert] = []

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
            if !widgetAppGroupAvailable {
                enqueueAlert(.widget)
                hasShownWidgetWarning = true
            }
            checkCloudSyncStatusForAlert()
            if cloudSyncEnabled {
                CloudSyncStatusChecker.refresh()
            }
            // Configure coach marks
            AppTips.configure()
            // Show welcome on first run
            if !welcomeCompleted {
                // Ensure it presents after initial setup
                DispatchQueue.main.async { self.showWelcome = true }
            }
        }
        .onChange(of: groups) { _, newValue in
            WidgetDataWriter.updateTopGroupSummary(groups: newValue)
        }
        .onChange(of: widgetAppGroupAvailable) { _, newValue in
            if !newValue && !hasShownWidgetWarning {
                enqueueAlert(.widget)
                hasShownWidgetWarning = true
            }
        }
        .onChange(of: cloudSyncEnabled) { _, newValue in
            if newValue {
                hasShownCloudWarning = false
                CloudSyncStatusChecker.refresh()
            } else {
                CloudSyncStatusReporter.update(.unknown)
                hasShownCloudWarning = false
            }
        }
        .onChange(of: cloudSyncStatusRaw) { _, _ in
            checkCloudSyncStatusForAlert()
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
                // Choose the most recent active group (computed in-memory)
                let sorted = groups.sorted { $0.lastActivity > $1.lastActivity }
                if let group = sorted.first(where: { !$0.isArchived }) ?? sorted.first {
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
        .alert(item: $activeSystemAlert) { alert in
            Alert(
                title: Text(alert.title),
                message: Text(alert.message),
                dismissButton: .default(Text("OK"), action: showNextAlert)
            )
        }
        .overlay(privacyOverlay())
        .fullScreenCover(isPresented: $showWelcome) {
            WelcomeView {
                welcomeCompleted = true
                showWelcome = false
            }
        }
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
    var cloudSyncStatus: CloudSyncStatus {
        CloudSyncStatus(rawValue: cloudSyncStatusRaw) ?? .unknown
    }

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

private extension ContentView {
    func enqueueAlert(_ alert: SystemAlert) {
        if activeSystemAlert == nil {
            activeSystemAlert = alert
        } else {
            alertQueue.append(alert)
        }
    }

    func showNextAlert() {
        if alertQueue.isEmpty {
            activeSystemAlert = nil
        } else {
            activeSystemAlert = alertQueue.removeFirst()
        }
    }

    func checkCloudSyncStatusForAlert() {
        guard cloudSyncEnabled else { return }

        let message: String?
        switch cloudSyncStatus {
        case .missingEntitlement:
            message = "This build is missing the CloudKit entitlement, so sync is disabled. Install an iCloud-signed build to enable syncing."
        case .accountUnavailable:
            message = "Sign in to iCloud on this device to turn on syncing."
        case .error:
            let trimmed = cloudSyncStatusMessage.trimmingCharacters(in: .whitespacesAndNewlines)
            message = trimmed.isEmpty ? "Cloud sync failed to start. Try again after restarting FairSplit." : trimmed
        default:
            message = nil
        }

        if let message, !hasShownCloudWarning {
            enqueueAlert(.cloud(message))
            hasShownCloudWarning = true
        }
    }
}

private enum SystemAlert: Identifiable {
    case widget
    case cloud(String)

    var id: String {
        switch self {
        case .widget: return "widget"
        case .cloud: return "cloud"
        }
    }

    var title: String {
        switch self {
        case .widget: return "Widget Unavailable"
        case .cloud: return "Cloud Sync Unavailable"
        }
    }

    var message: String {
        switch self {
        case .widget:
            return "This build is missing the shared App Group entitlement, so the widget cannot refresh. FairSplit will continue to work normally."
        case .cloud(let message):
            return message
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Group.self, Member.self, Expense.self, Settlement.self, RecurringExpense.self, Contact.self, DirectExpense.self, Comment.self, PersonalExpense.self, PersonalBudget.self], inMemory: true)
}
