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
                    .frame(maxWidth: .infinity,
                           maxHeight: tall ? proxy.size.height * 0.8 : nil)
                    .background(Palette.card,
                                in: RoundedRectangle(cornerRadius: 26, style: .continuous))
                    .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                    .padding(.horizontal, 12)
                    .padding(.bottom, 12)
                    .offset(y: shown ? drag : 1000)
                    .gesture(dragToDismiss)
                    .environment(\.blurPopupClose, close)
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
