//
//  plopApp.swift
//  plop
//
//  Created by Wen Kang Yap on 2/6/26.
//

import SwiftUI
import SwiftData

@main
struct plopApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Transaction.self,
            ExpenseCategory.self,
            RecurringRule.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                RecurringGenerator.generate(in: sharedModelContainer.mainContext)
            }
        }
    }
}
