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

    var body: some View {
        // Placeholder until the Home + Entry UI lands in PR2.
        Text("plop")
            .task {
                DefaultData.seedIfNeeded(in: modelContext)
            }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Transaction.self, ExpenseCategory.self], inMemory: true)
}
