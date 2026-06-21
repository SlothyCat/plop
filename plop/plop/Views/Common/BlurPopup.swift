import SwiftUI

/// Presents `card` as a handoff-style blurred bottom popup: a full-screen
/// `.ultraThinMaterial` scrim blurs the real screen behind, and an opaque rounded card
/// slides up from the bottom. Dismiss by tapping the scrim, dragging the card down, or
/// having the card's own controls call `\.blurPopupClose` from the environment.
extension View {
    func blurPopup<Card: View>(
        isPresented: Binding<Bool>,
        tall: Bool = false,
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder card: @escaping () -> Card
    ) -> some View {
        fullScreenCover(isPresented: isPresented, onDismiss: onDismiss) {
            BlurPopupContainer(isPresented: isPresented, tall: tall, card: card)
                .presentationBackground(.clear)
        }
        .transaction { $0.disablesAnimations = true }   // suppress the cover's own slide
    }

    func blurPopup<Item: Identifiable, Card: View>(
        item: Binding<Item?>,
        tall: Bool = false,
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder card: @escaping (Item) -> Card
    ) -> some View {
        fullScreenCover(item: item, onDismiss: onDismiss) { value in
            BlurPopupContainer(
                isPresented: Binding(get: { item.wrappedValue != nil },
                                     set: { if !$0 { item.wrappedValue = nil } }),
                tall: tall
            ) { card(value) }
                .presentationBackground(.clear)
        }
        .transaction { $0.disablesAnimations = true }
    }
}

/// Closure the card content calls to dismiss the popup *with* the slide-out animation.
/// Defaults to a no-op so previews and standalone use compile.
private struct BlurPopupCloseKey: EnvironmentKey {
    static let defaultValue: () -> Void = {}
}

extension EnvironmentValues {
    var blurPopupClose: () -> Void {
        get { self[BlurPopupCloseKey.self] }
        set { self[BlurPopupCloseKey.self] = newValue }
    }
}

/// The popup's available height (set when `tall`), so a scrolling card can cap its scroll
/// region and stay on-screen while the card itself hugs its content. `.infinity` when the
/// card should simply hug (non-tall).
private struct BlurPopupMaxHeightKey: EnvironmentKey {
    static let defaultValue: CGFloat = .infinity
}

extension EnvironmentValues {
    var blurPopupMaxHeight: CGFloat {
        get { self[BlurPopupMaxHeightKey.self] }
        set { self[BlurPopupMaxHeightKey.self] = newValue }
    }
}

/// Reports a view's height into a binding. Used to self-size a popup's scroll region to its
/// content: cap the `ScrollView` at this height so a tall popup shrinks to short content but
/// still scrolls (clipped by the card's own max height) when content is long. Uses
/// `onGeometryChange` (iOS 17+) — reliable inside a `ScrollView`, unlike a background
/// PreferenceKey.
extension View {
    func readHeight(into binding: Binding<CGFloat>) -> some View {
        onGeometryChange(for: CGFloat.self) { $0.size.height } action: { binding.wrappedValue = $0 }
    }
}

private struct BlurPopupContainer<Card: View>: View {
    @Binding var isPresented: Bool
    var tall: Bool
    @ViewBuilder var card: () -> Card

    @State private var shown = false
    @State private var drag: CGFloat = 0

    private let anim: Animation = .spring(response: 0.34, dampingFraction: 0.86)
    private let outDelay = 0.34

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .bottom) {
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .overlay(Color.black.opacity(0.18))
                    .ignoresSafeArea()
                    .opacity(shown ? 1 : 0)
                    .contentShape(Rectangle())
                    .onTapGesture { close() }

                card()
                    .frame(maxWidth: .infinity)
                    .background(Palette.card,
                                in: RoundedRectangle(cornerRadius: 26, style: .continuous))
                    .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                    .padding(.horizontal, 12)
                    .padding(.bottom, 12)
                    .offset(y: shown ? drag : 1000)
                    .gesture(dragToDismiss)
                    .environment(\.blurPopupClose, close)
                    .environment(\.blurPopupMaxHeight, tall ? proxy.size.height : .infinity)
            }
        }
        .onAppear { withAnimation(anim) { shown = true } }
    }

    private var dragToDismiss: some Gesture {
        DragGesture()
            .onChanged { drag = max(0, $0.translation.height) }
            .onEnded { value in
                if value.translation.height > 120
                    || value.predictedEndTranslation.height > 240 {
                    close()
                } else {
                    withAnimation(anim) { drag = 0 }
                }
            }
    }

    private func close() {
        withAnimation(anim) { shown = false; drag = 0 }
        DispatchQueue.main.asyncAfter(deadline: .now() + outDelay) { isPresented = false }
    }
}
