import SwiftUI

enum MacFretboardSizing {
    // Catalyst scales these points to about 460 screen points in the reference window.
    static let minimumSize = CGSize(width: 640, height: 600)

    static func fitted(_ preferred: CGSize, in available: CGSize) -> CGSize {
        CGSize(
            width: min(max(0, available.width), max(minimumSize.width, preferred.width)),
            height: min(max(0, available.height), max(minimumSize.height, preferred.height))
        )
    }

    static func resized(from start: CGSize, translation: CGSize, in available: CGSize) -> CGSize {
        // Both edges move because the board stays centered while resizing.
        fitted(CGSize(width: start.width + translation.width * 2,
                      height: start.height + translation.height * 2), in: available)
    }
}

#if targetEnvironment(macCatalyst)
struct MacResizableFretboard<Content: View>: View {
    @AppStorage("mac.fretboard.height") private var preferredHeight = 600.0
    @State private var dragStart: CGSize?
    @GestureState private var dragging = false
    @Namespace private var workspace
    @ViewBuilder let content: () -> Content

    var body: some View {
        GeometryReader { proxy in
            let available = CGSize(width: max(0, proxy.size.width - 12),
                                   height: max(0, proxy.size.height - 32))
            let height = MacFretboardSizing.fitted(
                CGSize(width: available.width, height: preferredHeight), in: available).height
            let size = CGSize(width: available.width, height: height)

            content()
                .frame(width: size.width, height: size.height)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay {
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(AppColors.mutedText.opacity(0.25), lineWidth: 1)
                        .allowsHitTesting(false)
                }
                .overlay(alignment: .bottomTrailing) {
                    Image(systemName: "arrow.up.and.down")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(AppColors.rootText)
                        .frame(width: 36, height: 36)
                        .background(AppColors.control, in: RoundedRectangle(cornerRadius: 8))
                        .contentShape(Rectangle())
                        .accessibilityLabel("mac.fretboard.resize")
                        .accessibilityAddTraits(.isButton)
                        .help(Text("mac.fretboard.resize.hint"))
                        .gesture(
                            DragGesture(coordinateSpace: .named(workspace))
                                .updating($dragging) { _, state, _ in state = true }
                                .onChanged { value in
                                    if dragStart == nil { dragStart = size }
                                    let resized = MacFretboardSizing.resized(
                                        from: dragStart ?? size, translation: value.translation, in: available)
                                    preferredHeight = resized.height
                                }
                                .onEnded { _ in dragStart = nil }
                        )
                        .padding(6)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        }
        .coordinateSpace(name: workspace)
        .onChange(of: dragging) { if !$0 { dragStart = nil } }
    }
}
#endif
