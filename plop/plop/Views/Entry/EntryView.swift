import SwiftUI
import SwiftData

/// Full-screen add/edit transaction screen. UI-only this feature: confirm builds a
/// draft but does not persist yet (TODO PR5). `editing` is forward-compat; only the
/// add flow is presented for now.
struct EntryView: View {
    var editing: Transaction?
    var initialRecurrence: RecurrenceInterval = .none

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ExpenseCategory.name) private var categories: [ExpenseCategory]

    @AppStorage(currencyCodeKey) private var currencyCode = deviceCurrencyCode()

    @State private var mode: TransactionType = .expense
    @State private var input = AmountInput(maxFractionDigits: currencyFractionDigits(currencyCode: deviceCurrencyCode()))
    @State private var note = ""
    @State private var date = Date.now
    @State private var selected: ExpenseCategory?
    @State private var recurrence: RecurrenceInterval = .none

    @State private var pickerOpen = false
    @State private var whenOpen = false
    @State private var recurOpen = false
    @State private var showingNewCategory = false
    @State private var showingRecurringConfirm = false
    @State private var showValidationErrors = false

    var body: some View {
        VStack(spacing: 0) {
            header
            Spacer(minLength: 8)
            RegisterDisplay(type: mode, currencySymbol: currencySymbol(currencyCode),
                            amount: input.display(), category: selected,
                            dateText: "\(dateLabel) · \(timeLabel)", amountInvalid: amountInvalid)
            belowCard
            Spacer(minLength: 8)
            detailPills
            keypad
            footer
        }
        .background(Palette.bg.ignoresSafeArea())
        .blurPopup(isPresented: $pickerOpen, tall: true) {
            CategoryPickerSheet(categories: categories, selected: $selected,
                                onAddNew: { pickerOpen = false; showingNewCategory = true })
        }
        .blurPopup(isPresented: $showingNewCategory) {
            CategoryFormView(onSave: { selected = $0 })
        }
        .blurPopup(isPresented: $whenOpen) {
            WhenSheet(date: $date)
        }
        .blurPopup(isPresented: $recurOpen) {
            RecurringSheet(recurrence: $recurrence)
        }
        .confirmationDialog("Recurring payment", isPresented: $showingRecurringConfirm,
                            titleVisibility: .visible) {
            Button("Create") { performSave() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This repeats \(recurringSummary(interval: recurrence, date: date)) "
                 + "until you stop it.")
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
                if let tx = editing {
                    circleButton("trash", danger: true) {
                        TransactionActions.delete(tx, in: modelContext)
                        Haptics.success()
                        dismiss()
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
    }

    // MARK: below the register (caption, recurring, note)

    private var belowCard: some View {
        VStack(spacing: 12) {
            if let message = validationCaption {
                Text(message)
                    .font(.system(size: 13.5, weight: .medium))
                    .foregroundStyle(Palette.danger)
                    .multilineTextAlignment(.center)
            }
            if recurrence != .none {
                Button { recurOpen = true } label: {
                    Label("Repeats \(recurringSummary(interval: recurrence, date: date))",
                          systemImage: "arrow.triangle.2.circlepath")
                        .font(.system(size: 13.5, weight: .semibold))
                        .foregroundStyle(Palette.ink60)
                }
            }
            noteRow
        }
        .padding(.top, 14)
    }

    private var noteRow: some View {
        HStack(spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "line.3.horizontal").foregroundStyle(Palette.ink40)
                TextField("Add Note", text: $note).font(.system(size: 15))
            }
            .padding(.vertical, 12).padding(.horizontal, 14)
            .frame(maxWidth: .infinity)
            .background(Palette.card, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Palette.ink12, lineWidth: 1))

            Button { input.backspace() } label: {
                Image(systemName: "delete.left")
                    .font(.system(size: 20)).foregroundStyle(Palette.ink60)
                    .frame(width: 54, height: 48)
                    .background(Palette.card, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Palette.ink12, lineWidth: 1))
            }
        }
        .padding(.horizontal, 18)
    }

    private var footer: some View {
        HStack(spacing: 10) {
            Rectangle().fill(Palette.ink12).frame(width: 40, height: 1)
            HStack(spacing: 6) {
                Text("Plop").font(.system(size: 13, weight: .bold)).foregroundStyle(Palette.ink60)
                Text("CASHIER").font(.system(size: 13, weight: .semibold)).tracking(3)
                    .foregroundStyle(Palette.ink40)
            }
            Rectangle().fill(Palette.ink12).frame(width: 40, height: 1)
        }
        .padding(.top, 10).padding(.bottom, 16)
    }

    // MARK: date + category pills

    private var detailPills: some View {
        HStack(spacing: 10) {
            Button { whenOpen = true } label: {
                HStack(spacing: 8) {
                    Image(systemName: "calendar")
                    Text(dateLabel).lineLimit(1)
                    Spacer(minLength: 6)
                    Text(timeLabel).foregroundStyle(Palette.ink40).lineLimit(1)
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Palette.ink)
                .padding(.vertical, 11)
                .padding(.horizontal, 14)
                .frame(maxWidth: .infinity)
                .background(Palette.card, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Palette.ink12, lineWidth: 1))
            }

            Button { pickerOpen = true } label: {
                HStack(spacing: 6) {
                    CategoryIconView(category: selected, fallbackSymbol: "square.grid.2x2")
                    Text(selected?.name ?? "Category")
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .frame(maxWidth: 90)
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(categoryInvalid ? Palette.danger
                                 : (selected != nil ? Palette.tileInk : Palette.ink60))
                .padding(.vertical, 11)
                .padding(.horizontal, 14)
                .background(selected.map { Color(hex: $0.colorHex) } ?? Palette.card,
                            in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(categoryInvalid ? Palette.danger : Palette.ink12,
                                                                   lineWidth: categoryInvalid ? 1.5 : 1))
            }
            .accessibilityIdentifier("categoryButton")
        }
        .padding(.horizontal, 18)
        .padding(.bottom, 14)
    }

    // MARK: keypad

    private var keypad: some View {
        Keypad(onKey: { input.press($0) }, onConfirm: confirm)
            .padding(.horizontal, 18)
            .padding(.bottom, 30)
    }

    // MARK: actions / helpers

    /// A transaction needs a positive amount AND a category.
    private var canSave: Bool { input.canSave && selected != nil }
    private var amountInvalid: Bool { showValidationErrors && !input.canSave }
    private var categoryInvalid: Bool { showValidationErrors && selected == nil }
    private var validationCaption: String? {
        guard showValidationErrors else { return nil }
        return entryValidationMessage(hasAmount: input.canSave, hasCategory: selected != nil)
    }

    private func confirm() {
        guard canSave else {
            showValidationErrors = true
            Haptics.error()
            return
        }
        if editing == nil && recurrence != .none {
            showingRecurringConfirm = true
        } else {
            performSave()
        }
    }

    private func performSave() {
        let draft = TransactionDraft(amount: input.value, type: mode, date: date,
                                     note: note.trimmingCharacters(in: .whitespaces),
                                     recurrence: recurrence, category: selected)
        if let tx = editing {
            TransactionActions.update(tx, with: draft)
        } else if draft.recurrence != .none {
            RecurringActions.create(from: draft, in: modelContext)
        } else {
            TransactionActions.add(draft, in: modelContext)
        }
        Haptics.success()
        dismiss()
    }

    private func prefillIfEditing() {
        guard let tx = editing else {
            input = AmountInput(maxFractionDigits: currencyFractionDigits(currencyCode: currencyCode))
            recurrence = initialRecurrence
            return
        }
        mode = tx.type
        note = tx.note
        date = tx.date
        recurrence = tx.recurrence
        selected = tx.category
        input = AmountInput(value: tx.amount,
                            maxFractionDigits: currencyFractionDigits(currencyCode: currencyCode))
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
