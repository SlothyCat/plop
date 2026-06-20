import SwiftUI
import SwiftData

/// Popup listing active recurring rules. Swipe a row to Stop (cancel) it: future
/// occurrences stop; past ones stay.
struct RecurringRulesSheet: View {
    @Query(sort: \RecurringRule.createdAt) private var rules: [RecurringRule]
    @Environment(\.modelContext) private var modelContext
    @AppStorage(currencyCodeKey) private var currencyCode = deviceCurrencyCode()
    @State private var pendingCancel: RecurringRule?
    @Environment(\.blurPopupClose) private var close

    var body: some View {
        NavigationStack {
            Group {
                if rules.isEmpty {
                    emptyState
                } else {
                    List {
                        ForEach(rules) { rule in row(rule) }
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .background(Palette.card)
            .navigationTitle("Recurring payments")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { close() }
                }
            }
            .confirmationDialog("Stop this recurring payment?",
                                isPresented: cancelDialogBinding,
                                titleVisibility: .visible,
                                presenting: pendingCancel) { rule in
                Button("Stop recurring", role: .destructive) {
                    RecurringActions.cancel(rule, in: modelContext)
                    pendingCancel = nil
                }
                Button("Keep", role: .cancel) { pendingCancel = nil }
            } message: { _ in
                Text("Future charges stop; past ones stay.")
            }
        }
    }

    private var cancelDialogBinding: Binding<Bool> {
        Binding(get: { pendingCancel != nil }, set: { if !$0 { pendingCancel = nil } })
    }

    private func row(_ rule: RecurringRule) -> some View {
        HStack(spacing: 12) {
            Image(systemName: rule.category?.symbolName ?? "arrow.triangle.2.circlepath")
                .font(.system(size: 16))
                .foregroundStyle(Palette.tileInk)
                .frame(width: 36, height: 36)
                .background(rule.category.map { Color(hex: $0.colorHex) } ?? Palette.accentSoft,
                            in: RoundedRectangle(cornerRadius: 10))
            VStack(alignment: .leading, spacing: 2) {
                Text(title(rule))
                    .font(.system(size: 16, weight: .semibold)).foregroundStyle(Palette.ink)
                Text(recurringSummary(interval: rule.interval, date: rule.startDate))
                    .font(.system(size: 13)).foregroundStyle(Palette.ink40)
            }
            Spacer()
            Text(formattedMoney(rule.amount, currencyCode: currencyCode))
                .font(.system(size: 15, weight: .semibold)).monospacedDigit()
                .foregroundStyle(Palette.ink)
        }
        .listRowBackground(Palette.card)
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) { pendingCancel = rule } label: {
                Label("Stop", systemImage: "xmark.circle")
            }
        }
    }

    private func title(_ rule: RecurringRule) -> String {
        if !rule.note.isEmpty { return rule.note }
        return rule.category?.name ?? "Recurring payment"
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "arrow.triangle.2.circlepath")
                .font(.system(size: 32)).foregroundStyle(Palette.ink40)
            Text("No recurring payments yet")
                .font(.system(size: 15)).foregroundStyle(Palette.ink40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#if DEBUG
#Preview {
    RecurringRulesSheet().modelContainer(SampleData.previewContainer())
}
#endif
