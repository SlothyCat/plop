//
//  ContentView.swift
//  plop
//
//  Created by Wen Kang Yap on 2/6/26.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage(themeModeKey) private var themeModeRaw = ThemeMode.automatic.rawValue

    var body: some View {
        RootView()
            .preferredColorScheme((ThemeMode(rawValue: themeModeRaw) ?? .automatic).colorScheme)
            .task {
                DefaultData.seedIfNeeded(in: modelContext)
            }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Transaction.self, ExpenseCategory.self], inMemory: true)
}
