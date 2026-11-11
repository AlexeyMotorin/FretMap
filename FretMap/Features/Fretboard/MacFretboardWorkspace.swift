import SwiftUI

enum MacSidebarSizing {
    static func fitted(_ preferred: CGFloat, in windowWidth: CGFloat) -> CGFloat {
        min(max(320, windowWidth / 3), max(320, preferred))
    }
}

#if targetEnvironment(macCatalyst)
struct MacFretboardWorkspace<Settings: View, Board: View>: View {
    @AppStorage("mac.settings.width") private var preferredWidth = 320.0
    @State private var dragStart: CGFloat?
    @GestureState private var dragging = false
    @Namespace private var workspace
    var showsSettings = true
    var resizesBoard = true
    @ViewBuilder let settings: () -> Settings
    @ViewBuilder let board: () -> Board

    var body: some View {
        GeometryReader { proxy in
            let width = MacSidebarSizing.fitted(preferredWidth, in: proxy.size.width)
            HStack(spacing: 0) {
                if showsSettings {
                    settings().frame(width: width).frame(maxHeight: .infinity)
                    ZStack {
                        AppColors.panel
                        Rectangle().fill(AppColors.border).frame(width: 1)
                        Capsule().fill(AppColors.mutedText).frame(width: 3, height: 44)
                    }
                    .frame(width: 10)
                    .contentShape(Rectangle())
                    .accessibilityLabel("mac.sidebar.resize")
                    .help(Text("mac.sidebar.resize.hint"))
                    .gesture(
                        DragGesture(coordinateSpace: .named(workspace))
                            .updating($dragging) { _, state, _ in state = true }
                            .onChanged { value in
                                if dragStart == nil { dragStart = width }
                                preferredWidth = MacSidebarSizing.fitted(
                                    (dragStart ?? width) + value.translation.width, in: proxy.size.width)
                            }
                            .onEnded { _ in dragStart = nil }
                    )
                }
                if resizesBoard {
                    MacResizableFretboard(content: board)
                } else {
                    board().frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
        .coordinateSpace(name: workspace)
        .onChange(of: dragging) { if !$0 { dragStart = nil } }
    }
}
#endif
