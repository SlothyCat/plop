import SwiftUI

/// Export dialog: pick a range, run the export, and show progress / success (with a
/// link to the sheet) / error. The sheet hugs its content via a measured detent.
struct ExportSheet: View {
    let transactions: [Transaction]
    let categories: [ExpenseCategory]
    @Environment(\.blurPopupClose) private var close

    @AppStorage(currencyCodeKey) private var currencyCode = deviceCurrencyCode()
    @AppStorage(budgetModeKey) private var budgetModeRaw = BudgetMode.category.rawValue
    @AppStorage(generalBudgetKey) private var generalBudget = ""
    @Environment(\.openURL) private var openURL

    @State private var service = ExportService.live()
    @State private var rangeKind: RangeKind = .thisMonth
    @State private var from = Calendar.current.date(byAdding: .month, value: -1, to: .now) ?? .now
    @State private var to = Date.now
    @State private var emptyNotice = false

    private enum RangeKind: String, CaseIterable {
        case thisMonth = "This month"
        case dateRange = "Date range"
    }

    var body: some View {
        content
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
            .onChange(of: service.phase) { _, phase in
                if case .success = phase { Haptics.success() }
            }
    }

    @ViewBuilder private var content: some View {
        switch service.phase {
        case .running: phaseRunning
        case .success(let url): phaseSuccess(url)
        default: form
        }
    }

    private var form: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 20)).foregroundStyle(Palette.tileInk)
                    .frame(width: 42, height: 42)
                    .background(Palette.accentSoft, in: RoundedRectangle(cornerRadius: 13))
                Text("Export to Google Sheets")
                    .font(.system(size: 20, weight: .bold)).foregroundStyle(Palette.ink)
            }

            Text("Your transactions for the selected period are sent to a sheet in your "
                 + "Google account.")
                .font(.system(size: 14)).foregroundStyle(Palette.ink60)
                .fixedSize(horizontal: false, vertical: true)

            Picker("Range", selection: $rangeKind) {
                ForEach(RangeKind.allCases, id: \.self) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)

            if rangeKind == .dateRange {
                HStack(spacing: 10) {
                    DatePicker("From", selection: $from, displayedComponents: .date)
                        .labelsHidden()
                    Text("to").foregroundStyle(Palette.ink40)
                    DatePicker("To", selection: $to, in: from..., displayedComponents: .date)
                        .labelsHidden()
                }
                .tint(Palette.accent)
            }

            if case .failure(let error) = service.phase, let message = error.message {
                Text(message).font(.system(size: 13.5)).foregroundStyle(Palette.ink)
            }
            if emptyNotice {
                Text("No transactions in this range.")
                    .font(.system(size: 13.5)).foregroundStyle(Palette.danger)
            }

            VStack(spacing: 8) {
                Button { Task { await runExport() } } label: {
                    Text("Export")
                }
                .buttonStyle(PopupPrimaryButton())
            }
        }
    }

    private var phaseRunning: some View {
        VStack(spacing: 14) {
            ProgressView().controlSize(.large)
            Text("Exporting…").font(.system(size: 15)).foregroundStyle(Palette.ink60)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }

    private func phaseSuccess(_ url: URL) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 44)).foregroundStyle(Palette.accent)
            Text("Export complete").font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Palette.ink)
            Button { openURL(url) } label: {
                Label("Open in Google Sheets", systemImage: "arrow.up.right.square")
            }
            .buttonStyle(PopupPrimaryButton())
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    private func runExport() async {
        emptyNotice = false
        let range: ExportRange = rangeKind == .thisMonth
            ? .thisMonth
            : .dateRange(min(from, to)...max(from, to))
        let sheets = buildExportSheets(
            transactions: transactions, categories: categories,
            options: ExportOptions(range: range,
                                   budgetMode: BudgetMode(rawValue: budgetModeRaw) ?? .category,
                                   generalBudget: generalBudget, currencyCode: currencyCode))
        guard !sheets.isEmpty else { emptyNotice = true; Haptics.error(); return }
        await service.run(monthSheets: sheets)
    }
}

#if DEBUG
#Preview {
    ExportSheet(transactions: [], categories: [])
}
#endif
