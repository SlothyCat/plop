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
    @State private var showSplash = true

    var body: some View {
        ZStack {
            RootView()
                .preferredColorScheme((ThemeMode(rawValue: themeModeRaw) ?? .automatic).colorScheme)
                .task {
                    DefaultData.seedIfNeeded(in: modelContext)
                }

            if showSplash {
                SplashView { withAnimation(.easeOut(duration: 0.35)) { showSplash = false } }
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Transaction.self, ExpenseCategory.self, RecurringRule.self],
                        inMemory: true)
}
