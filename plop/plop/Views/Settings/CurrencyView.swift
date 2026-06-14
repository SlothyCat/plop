import SwiftUI

/// Picks the app-wide display currency (no conversion). Writing @AppStorage re-renders
/// every money view that reads it.
struct CurrencyView: View {
    @AppStorage(currencyCodeKey) private var currencyCode = deviceCurrencyCode()

    var body: some View {
        List {
            Section {
                ForEach(currencyChoices, id: \.self) { code in
                    Button { currencyCode = code } label: { row(code) }
                        .buttonStyle(.plain)
                }
            } footer: {
                Text("Amounts aren't converted — only the symbol and decimal places change.")
            }
        }
        .scrollContentBackground(.hidden)
        .background(Palette.bg)
        .navigationTitle("Currency")
    }

    private func row(_ code: String) -> some View {
        HStack(spacing: 12) {
            Text(code)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Palette.ink)
                .frame(width: 44, alignment: .leading)
            Text(currencySymbol(code)).foregroundStyle(Palette.ink40)
            Text(currencyDisplayName(code)).foregroundStyle(Palette.ink40).lineLimit(1)
            Spacer()
            if code == currencyCode {
                Image(systemName: "checkmark").foregroundStyle(Palette.accent)
            }
        }
    }
}

#if DEBUG
#Preview { NavigationStack { CurrencyView() } }
#endif
