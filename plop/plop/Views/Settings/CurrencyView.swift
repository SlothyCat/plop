import SwiftUI

/// Picks the app-wide display currency (no conversion). Matches the handoff Currency popup.
struct CurrencyView: View {
    @AppStorage(currencyCodeKey) private var currencyCode = deviceCurrencyCode()
    @Environment(\.blurPopupClose) private var close
    @State private var listHeight: CGFloat = 0

    var body: some View {
        VStack(spacing: 0) {
            header
            ScrollView {
                LazyVStack(spacing: 10) {
                    ForEach(currencyChoices, id: \.self) { code in
                        Button { currencyCode = code } label: { row(code) }
                            .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 4)
                .readHeight(into: $listHeight)
            }
            .frame(maxHeight: listHeight == 0 ? nil : listHeight)
            doneBar
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Currency")
                .font(.system(size: 24, weight: .bold)).foregroundStyle(Palette.ink)
            Text("Pick the currency symbol used across the app. Amounts aren't converted.")
                .font(.system(size: 15)).foregroundStyle(Palette.ink60)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20).padding(.top, 22).padding(.bottom, 12)
    }

    private func row(_ code: String) -> some View {
        let on = code == currencyCode
        return HStack(spacing: 13) {
            Text(currencyFlag(code))
                .font(.system(size: 22))
                .frame(width: 44, height: 44)
                .background(.white, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Palette.ink12, lineWidth: 1))
            VStack(alignment: .leading, spacing: 1) {
                Text(code)
                    .font(.system(size: 17, weight: .semibold)).foregroundStyle(Palette.ink)
                Text(currencyDisplayName(code))
                    .font(.system(size: 13.5)).foregroundStyle(Palette.ink40).lineLimit(1)
            }
            Spacer()
            if on {
                Image(systemName: "checkmark")
                    .font(.system(size: 16, weight: .semibold)).foregroundStyle(Palette.ink)
            }
        }
        .padding(12)
        .background(on ? Palette.accent : Palette.card,
                    in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16)
            .stroke(on ? Color.clear : Palette.ink12, lineWidth: 1))
    }

    private var doneBar: some View {
        Button("Done") { close() }
            .font(.system(size: 17, weight: .semibold)).foregroundStyle(Palette.ink)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .overlay(Rectangle().fill(Palette.hair).frame(height: 1), alignment: .top)
    }
}

#if DEBUG
#Preview { CurrencyView() }
#endif
