#if DEBUG
import Foundation
import SwiftData

/// Sample fixtures for #Preview canvases only (excluded from release via #if DEBUG).
/// Dates are relative to "now" so they always fall inside the current week/month.
enum SampleData {
    /// In-memory container pre-seeded with sample transactions, for @Query previews.
    @MainActor
    static func previewContainer() -> ModelContainer {
        do {
            let container = try ModelContainer(
                for: Transaction.self, ExpenseCategory.self, RecurringRule.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            )
            for tx in transactions() {
                container.mainContext.insert(tx)
            }
            return container
        } catch {
            fatalError("Failed to build preview container: \(error)")
        }
    }

    /// In-memory container seeded with many categories, to preview tall/scrolling popups
    /// (e.g. the budget editor) where a long category list must stay usable.
    @MainActor
    static func manyCategoriesContainer() -> ModelContainer {
        do {
            let container = try ModelContainer(
                for: Transaction.self, ExpenseCategory.self, RecurringRule.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            )
            let names = ["Food", "Transport", "Shopping", "Bills", "Entertainment", "School",
                         "Subscriptions", "Health", "Travel", "Gifts", "Groceries", "Rent",
                         "Utilities", "Fitness", "Pets"]
            let palette = ["#FFEBCC", "#BFDDF0", "#8CC0EB", "#FFF9D2"]
            for (i, name) in names.enumerated() {
                container.mainContext.insert(
                    ExpenseCategory(name: name, symbolName: "tag.fill",
                                    colorHex: palette[i % palette.count],
                                    budget: Decimal(50 + i * 10)))
            }
            return container
        } catch {
            fatalError("Failed to build preview container: \(error)")
        }
    }

    static func categories() -> [ExpenseCategory] {
        [
            ExpenseCategory(name: "Food", symbolName: "fork.knife", colorHex: "#FFEBCC"),
            ExpenseCategory(name: "School", symbolName: "graduationcap.fill", colorHex: "#8CC0EB"),
            ExpenseCategory(name: "Subscriptions", symbolName: "play.tv.fill", colorHex: "#FFF9D2"),
        ]
    }

    static func transactions() -> [Transaction] {
        let cats = categories()
        let food = cats[0], school = cats[1], subs = cats[2]
        return [
            Transaction(amount: 612, type: .expense, date: daysAgo(0, 22, 41),
                        note: "Semester tuition", category: school),
            Transaction(amount: Decimal(string: "5.10")!, type: .expense, date: daysAgo(0, 13, 16),
                        category: school),
            Transaction(amount: 4, type: .expense, date: daysAgo(1, 13, 16),
                        note: "Coffee run", category: food),
            Transaction(amount: Decimal(string: "6.48")!, type: .expense, date: daysAgo(3, 0, 8),
                        note: "Music", recurrence: .monthly, category: subs),
            Transaction(amount: 1200, type: .income, date: daysAgo(8, 10, 0),
                        note: "Scholarship", category: school),
        ]
    }

    static func sampleGroup() -> DayGroup {
        groupByDay([transactions()[0], transactions()[1]], calendar: .current).first!
    }

    private static func daysAgo(_ n: Int, _ hour: Int, _ minute: Int) -> Date {
        let cal = Calendar.current
        let base = cal.date(byAdding: .day, value: -n, to: .now)!
        return cal.date(bySettingHour: hour, minute: minute, second: 0, of: base)!
    }
}
#endif
