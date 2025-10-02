//
//  FairSplitApp.swift
//  FairSplit
//
//  Created by Shaun Stanley on 8/24/25.
//

import SwiftUI
import SwiftData

@main
struct FairSplitApp: App {
    private let modelContainer: ModelContainer

    init() {
        do {
            modelContainer = try Self.makeModelContainer()
        } catch {
            Diagnostics.event("Cloud sync disabled — container creation failed: \(error.localizedDescription)")
            UserDefaults.standard.set(false, forKey: AppSettings.cloudSyncKey)
            modelContainer = try! Self.makeModelContainer(forceLocal: true)
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(modelContainer)
    }
}

private extension FairSplitApp {
    static func makeModelContainer(forceLocal: Bool = false) throws -> ModelContainer {
        let useCloudKit = !forceLocal && UserDefaults.standard.bool(forKey: AppSettings.cloudSyncKey)
        if useCloudKit {
            let configuration = ModelConfiguration(
                cloudKitDatabase: .automatic
            )
            return try ModelContainer(
                for: Group.self,
                Member.self,
                Expense.self,
                ExpenseShare.self,
                Comment.self,
                ItemizedItem.self,
                Settlement.self,
                RecurringExpense.self,
                Contact.self,
                DirectExpense.self,
                PersonalExpense.self,
                configurations: configuration
            )
        } else {
            return try ModelContainer(
                for: Group.self,
                Member.self,
                Expense.self,
                ExpenseShare.self,
                Comment.self,
                ItemizedItem.self,
                Settlement.self,
                RecurringExpense.self,
                Contact.self,
                DirectExpense.self,
                PersonalExpense.self
            )
        }
    }
}
