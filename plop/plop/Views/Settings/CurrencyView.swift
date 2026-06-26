import SwiftUI
import UIKit

/// Picks the app-wide display currency (no conversion). Matches the handoff Currency popup.
struct CurrencyView: View {
    @AppStorage(currencyCodeKey) private var currencyCode = deviceCurrencyCode()
    @Environment(\.blurPopupClose) private var close
    @Environment(\.blurPopupMaxHeight) private var maxHeight
    @State private var listHeight: CGFloat = 0

    private var scrollCap: CGFloat {
        let ceiling = maxHeight.isFinite ? maxHeight * 0.7 : 100_000
        return listHeight == 0 ? ceiling : min(listHeight, ceiling)
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            ScrollView {
                LazyVStack(spacing: 10) {
                    ForEach(currencyChoices, id: \.self) { code in
                        Button {
                            if code != currencyCode { Haptics.success() }
                            currencyCode = code
                        } label: { row(code) }
                            .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 4)
                .readHeight(into: $listHeight)
            }
            .frame(maxHeight: scrollCap)
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
            flag(code)
                .frame(width: 38, height: 38)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Palette.ink12, lineWidth: 1))
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
        .contentShape(Rectangle())
    }

    @ViewBuilder private func flag(_ code: String) -> some View {
        if UIImage(named: currencyFlagAsset(code)) != nil {
            Image(currencyFlagAsset(code)).resizable().scaledToFill()
        } else {
            Text(currencySymbol(code))
                .font(.system(size: 15, weight: .bold)).foregroundStyle(Palette.tileInk)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Palette.card)
        }
    }

}

#if DEBUG
#Preview { CurrencyView() }
#endif
