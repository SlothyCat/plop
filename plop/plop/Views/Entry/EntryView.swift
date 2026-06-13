import SwiftUI
import SwiftData

/// Full-screen add/edit transaction screen. UI-only this feature: confirm builds a
/// draft but does not persist yet (TODO PR5). `editing` is forward-compat; only the
/// add flow is presented for now.
struct EntryView: View {
    var editing: Transaction?

    @Environment(\.dismiss) private var dismiss
    @Query(sort: \ExpenseCategory.name) private var categories: [ExpenseCategory]

    @State private var mode: TransactionType = .expense
    @State private var input = AmountInput(maxFractionDigits: currencyFractionDigits())
    @State private var note = ""
    @State private var date = Date.now
    @State private var selected: ExpenseCategory?
    @State private var recurrence: RecurrenceInterval = .none

    @State private var pickerOpen = false
    @State private var whenOpen = false
    @State private var recurOpen = false

    var body: some View {
        VStack(spacing: 0) {
            header
            Spacer()
            amountArea
            Spacer()
            detailPills
            keypad
        }
        .background(Palette.bg.ignoresSafeArea())
        .sheet(isPresented: $pickerOpen) {
            CategoryPickerSheet(categories: categories, selected: $selected) { pickerOpen = false }
        }
        .sheet(isPresented: $whenOpen) {
            WhenSheet(date: $date) { whenOpen = false }
        }
        .sheet(isPresented: $recurOpen) {
            RecurringSheet(recurrence: $recurrence) { recurOpen = false }
        }
        .onAppear(perform: prefillIfEditing)
    }

    // MARK: header

    private var header: some View {
        HStack {
            circleButton("xmark") { dismiss() }
            Spacer()
            SegmentedToggle(selection: $mode)
            Spacer()
            HStack(spacing: 8) {
                circleButton("arrow.triangle.2.circlepath", active: recurrence != .none) { recurOpen = true }
                if editing != nil {
                    circleButton("trash", danger: true) {
                        // TODO(PR5): delete via TransactionActions.delete
                        dismiss()
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
    }

    // MARK: amount

    private var amountArea: some View {
        VStack(spacing: 18) {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(currencySymbol)
                    .font(.system(size: 40, weight: .medium))
                    .foregroundStyle(Palette.ink40)
                Text(input.display())
                    .font(.system(size: 66, weight: .semibold))
                    .monospacedDigit()
                    .foregroundStyle(Palette.ink)
            }

            ZStack {
                notePill
                HStack {
                    Spacer()
                    Button { input.backspace() } label: {
                        Image(systemName: "delete.left")
                            .font(.system(size: 22))
                            .foregroundStyle(Palette.ink60)
                    }
                    .padding(.trailing, 24)
                }
            }

            if recurrence != .none {
                Button { recurOpen = true } label: {
                    Label("Repeats \(recurrence.rawValue)", systemImage: "arrow.triangle.2.circlepath")
                        .font(.system(size: 13.5, weight: .semibold))
                        .foregroundStyle(Palette.ink60)
                }
            }
        }
    }

    private var notePill: some View {
        TextField("Add Note", text: $note)
            .multilineTextAlignment(.center)
            .font(.system(size: 15))
            .padding(.vertical, 9)
            .padding(.horizontal, 16)
            .background(Palette.card, in: Capsule())
            .overlay(Capsule().stroke(Palette.ink12, lineWidth: 1))
            .frame(maxWidth: 240)
    }

    // MARK: date + category pills

    private var detailPills: some View {
        HStack(spacing: 10) {
            Button { whenOpen = true } label: {
                HStack {
                    Label(dateLabel, systemImage: "calendar")
                    Spacer()
                    Text(timeLabel).foregroundStyle(Palette.ink40)
                }
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Palette.ink)
                .padding(.vertical, 11)
                .padding(.horizontal, 16)
                .background(Palette.card, in: Capsule())
                .overlay(Capsule().stroke(Palette.ink12, lineWidth: 1))
            }

            Button { pickerOpen = true } label: {
                HStack {
                    Image(systemName: selected?.symbolName ?? "square.grid.2x2")
                    Text(selected?.name ?? "Category")
                }
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(selected != nil ? Palette.tileInk : Palette.ink60)
                .padding(.vertical, 11)
                .padding(.horizontal, 16)
                .background(selected.map { Color(hex: $0.colorHex) } ?? Palette.card, in: Capsule())
                .overlay(Capsule().stroke(Palette.ink12, lineWidth: 1))
            }
        }
        .padding(.horizontal, 18)
        .padding(.bottom, 14)
    }

    // MARK: keypad

    private var keypad: some View {
        Keypad(onKey: { input.press($0) }, onConfirm: confirm, canConfirm: input.canSave)
            .padding(.horizontal, 18)
            .padding(.bottom, 30)
    }

    // MARK: actions / helpers

    private func confirm() {
        guard input.canSave else { return }
        // TODO(PR5): persist via TransactionActions.add(draft, in: context)
        _ = TransactionDraft(amount: input.value, type: mode, date: date,
                             note: note.trimmingCharacters(in: .whitespaces),
                             recurrence: recurrence, category: selected)
        dismiss()
    }

    private func prefillIfEditing() {
        guard let tx = editing else { return }
        mode = tx.type
        note = tx.note
        date = tx.date
        recurrence = tx.recurrence
        selected = tx.category
        input = AmountInput(value: tx.amount, maxFractionDigits: currencyFractionDigits())
    }

    private func circleButton(_ systemImage: String, active: Bool = false,
                              danger: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(active ? Palette.tileInk : Palette.ink)
                .frame(width: 42, height: 42)
                .background(active ? Palette.accent : (danger ? Palette.ink.opacity(0.06) : Palette.card),
                            in: Circle())
                .overlay(Circle().stroke(active ? Color.clear : Palette.ink12, lineWidth: 1))
        }
    }

    private var currencySymbol: String { Locale.current.currencySymbol ?? "$" }

    private var dateLabel: String {
        if Calendar.current.isDateInToday(date) { return "Today" }
        if Calendar.current.isDateInYesterday(date) { return "Yesterday" }
        return date.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated))
    }

    private var timeLabel: String { date.formatted(date: .omitted, time: .shortened) }
}

#if DEBUG
#Preview {
    EntryView().modelContainer(SampleData.previewContainer())
}
#endif
