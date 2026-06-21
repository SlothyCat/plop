import SwiftUI
import SwiftData

/// Lists active recurring rules as a height-sensitive blur popup. Tap a row's stop button to
/// cancel it (future occurrences stop; past ones stay). Done at the bottom, like the others.
struct RecurringRulesSheet: View {
    @Query(sort: \RecurringRule.createdAt) private var rules: [RecurringRule]
    @Environment(\.modelContext) private var modelContext
    @Environment(\.blurPopupClose) private var close
    @Environment(\.blurPopupMaxHeight) private var maxHeight
    @AppStorage(currencyCodeKey) private var currencyCode = deviceCurrencyCode()
    @State private var pendingCancel: RecurringRule?
    @State private var listHeight: CGFloat = 0

    private var scrollCap: CGFloat {
        let ceiling = maxHeight.isFinite ? maxHeight * 0.7 : 100_000
        return listHeight == 0 ? ceiling : min(listHeight, ceiling)
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            if rules.isEmpty {
                emptyState
            } else {
                ScrollView {
                    VStack(spacing: 8) { ForEach(rules) { row($0) } }
                        .padding(.horizontal, 20).padding(.vertical, 4)
                        .readHeight(into: $listHeight)
                }
                .frame(maxHeight: scrollCap)
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

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Recurring payments")
                .font(.system(size: 24, weight: .bold)).foregroundStyle(Palette.ink)
            Text("Stop a payment to end its future charges; past ones stay.")
                .font(.system(size: 15)).foregroundStyle(Palette.ink60)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 20).padding(.top, 22).padding(.bottom, 12)
    }

    private func row(_ rule: RecurringRule) -> some View {
        HStack(spacing: 12) {
            CategoryIconView(category: rule.category, fallbackSymbol: "arrow.triangle.2.circlepath")
                .font(.system(size: 16)).foregroundStyle(Palette.tileInk)
                .frame(width: 38, height: 38)
                .background(rule.category.map { Color(hex: $0.colorHex) } ?? Palette.accentSoft,
                            in: RoundedRectangle(cornerRadius: 11, style: .continuous))
            VStack(alignment: .leading, spacing: 1) {
                Text(title(rule))
                    .font(.system(size: 16, weight: .semibold)).foregroundStyle(Palette.ink)
                Text(recurringSummary(interval: rule.interval, date: rule.startDate))
                    .font(.system(size: 13)).foregroundStyle(Palette.ink40)
            }
            Spacer(minLength: 8)
            Text(formattedMoney(rule.amount, currencyCode: currencyCode))
                .font(.system(size: 15, weight: .semibold)).monospacedDigit()
                .foregroundStyle(Palette.ink)
            Button { pendingCancel = rule } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 18)).foregroundStyle(Palette.ink40)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 10).padding(.vertical, 9)
        .background(Palette.field, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Palette.ink12, lineWidth: 1))
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "arrow.triangle.2.circlepath")
                .font(.system(size: 32)).foregroundStyle(Palette.ink40)
            Text("No recurring payments yet")
                .font(.system(size: 15)).foregroundStyle(Palette.ink40)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 40)
    }

    private var cancelDialogBinding: Binding<Bool> {
        Binding(get: { pendingCancel != nil }, set: { if !$0 { pendingCancel = nil } })
    }

    private func title(_ rule: RecurringRule) -> String {
        if !rule.note.isEmpty { return rule.note }
        return rule.category?.name ?? "Recurring payment"
    }
}

#if DEBUG
#Preview {
    RecurringRulesSheet().modelContainer(SampleData.previewContainer())
}
#endif
