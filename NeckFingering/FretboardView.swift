import SwiftUI

struct FretboardView: View {
    let tuning: TuningPreset
    let fretCount: Int
    var visibleFretRange: ClosedRange<Int>? = nil
    let markers: [FretMarker]
    let barres: [ChordBarre]
    let selectedPositions: Set<FretPosition>
    let customMode: Bool
    let onTapPosition: ((FretPosition) -> Void)?
    let onSwipe: (() -> Void)?

    private let openStringWidth: CGFloat = 54
    private let fretWidth: CGFloat = 62
    private let verticalPadding: CGFloat = 36
    private let horizontalPadding: CGFloat = 20

    private var displayedStrings: [GuitarString] { Array(tuning.strings.reversed()) }
    var body: some View {
        GeometryReader { proxy in
            let boardHeight = max(120, proxy.size.height)
            let layout = fretLayout(for: proxy.size.width)

            if visibleFretRange == nil {
                ScrollView(.horizontal) {
                    fretboardCanvas(boardHeight: boardHeight, layout: layout)
                        .padding(.horizontal, 12)
                        .contentShape(Rectangle())
                        .closeSettingsOnSingleFingerDrag(onSwipe)
                }
                .scrollIndicators(.hidden)
                .background(AppColors.fretboard)
                .frame(width: proxy.size.width, height: proxy.size.height, alignment: .topLeading)
                .contentShape(Rectangle())
                .closeSettingsOnSingleFingerDrag(onSwipe)
            } else {
                fretboardCanvas(boardHeight: boardHeight, layout: layout)
                    .frame(width: proxy.size.width, height: proxy.size.height, alignment: .topLeading)
                    .contentShape(Rectangle())
                    .background(AppColors.fretboard)
            }
        }
        .background(AppColors.fretboard)
    }

    private func fretboardCanvas(boardHeight: CGFloat, layout: FretLayout) -> some View {
        ZStack(alignment: .topLeading) {
            Rectangle()
                .fill(AppColors.fretboard)
                .overlay(boardTexture)
                .frame(width: layout.boardWidth, height: boardHeight)

            fretLines(boardHeight: boardHeight, layout: layout)
            fretNumbers(layout: layout)
            inlays(boardHeight: boardHeight, layout: layout)
            strings(boardHeight: boardHeight, layout: layout)
            barreViews(boardHeight: boardHeight, layout: layout)
            markerViews(boardHeight: boardHeight, layout: layout)

            if customMode {
                tapTargets(boardHeight: boardHeight, layout: layout)
            }
        }
        .frame(width: layout.boardWidth, height: boardHeight)
    }

    private func fretLayout(for availableWidth: CGFloat) -> FretLayout {
        let range = normalizedVisibleRange
        guard visibleFretRange != nil else {
            return FretLayout(
                range: range,
                fretWidth: fretWidth,
                boardWidth: openStringWidth + CGFloat(fretCount) * fretWidth + horizontalPadding * 2
            )
        }

        let contentWidth = max(160, availableWidth - horizontalPadding * 2)
        if range.lowerBound == 0 {
            let fretSlots = max(range.upperBound, 1)
            let fittedFretWidth = max(30, (contentWidth - openStringWidth) / CGFloat(fretSlots))
            return FretLayout(
                range: range,
                fretWidth: fittedFretWidth,
                boardWidth: availableWidth
            )
        }

        let fretSlots = max(range.upperBound - range.lowerBound + 1, 1)
        let fittedFretWidth = max(30, contentWidth / CGFloat(fretSlots))
        return FretLayout(
            range: range,
            fretWidth: fittedFretWidth,
            boardWidth: availableWidth
        )
    }

    private var normalizedVisibleRange: ClosedRange<Int> {
        guard let visibleFretRange else { return 0...fretCount }
        let lower = max(0, min(visibleFretRange.lowerBound, fretCount))
        let upper = max(lower, min(visibleFretRange.upperBound, fretCount))
        return lower...upper
    }

    private struct FretLayout {
        let range: ClosedRange<Int>
        let fretWidth: CGFloat
        let boardWidth: CGFloat

        var visibleFrets: [Int] {
            Array(range)
        }

        func contains(fret: Int) -> Bool {
            range.contains(fret)
        }

        func noteX(
            _ fret: Int,
            openStringWidth: CGFloat,
            horizontalPadding: CGFloat
        ) -> CGFloat {
            if range.lowerBound == 0 {
                return fret == 0
                    ? horizontalPadding + openStringWidth / 2
                    : horizontalPadding + openStringWidth + (CGFloat(fret) - 0.5) * fretWidth
            }

            return horizontalPadding + (CGFloat(fret - range.lowerBound) + 0.5) * fretWidth
        }

        func fretLineX(
            _ fret: Int,
            openStringWidth: CGFloat,
            horizontalPadding: CGFloat
        ) -> CGFloat {
            if range.lowerBound == 0 {
                return horizontalPadding + openStringWidth + CGFloat(fret) * fretWidth
            }

            return horizontalPadding + CGFloat(fret - range.lowerBound + 1) * fretWidth
        }

        func leftBoundaryX(horizontalPadding: CGFloat) -> CGFloat {
            horizontalPadding
        }

        func stringStartX(horizontalPadding: CGFloat) -> CGFloat {
            horizontalPadding
        }

        func stringEndX(horizontalPadding: CGFloat) -> CGFloat {
            boardWidth - horizontalPadding
        }

        func stringWidth(horizontalPadding: CGFloat) -> CGFloat {
            max(0, boardWidth - horizontalPadding * 2)
        }
    }

    private var boardTexture: some View {
        LinearGradient(
            colors: [Color.white.opacity(0.04), Color.black.opacity(0.08), Color.white.opacity(0.03)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private func fretLines(boardHeight: CGFloat, layout: FretLayout) -> some View {
        ZStack(alignment: .topLeading) {
            if layout.range.lowerBound == 0 {
                Rectangle()
                    .fill(AppColors.nut)
                    .frame(width: 12, height: boardHeight)
                    .position(x: horizontalPadding + openStringWidth, y: boardHeight / 2)
            } else {
                Rectangle()
                    .fill(LinearGradient(colors: [.white.opacity(0.75), .gray.opacity(0.5), .white.opacity(0.65)], startPoint: .leading, endPoint: .trailing))
                    .frame(width: 3, height: boardHeight)
                    .position(x: layout.leftBoundaryX(horizontalPadding: horizontalPadding), y: boardHeight / 2)
            }

            ForEach(layout.range.lowerBound == 0 ? Array(1...max(layout.range.upperBound, 1)) : layout.visibleFrets, id: \.self) { fret in
                Rectangle()
                    .fill(LinearGradient(colors: [.white.opacity(0.85), .gray.opacity(0.55), .white.opacity(0.7)], startPoint: .leading, endPoint: .trailing))
                    .frame(width: fret % 12 == 0 ? 5 : 3, height: boardHeight)
                    .shadow(color: .black.opacity(0.35), radius: 2, x: 2, y: 0)
                    .position(x: layout.fretLineX(fret, openStringWidth: openStringWidth, horizontalPadding: horizontalPadding), y: boardHeight / 2)
            }
        }
    }

    private func fretNumbers(layout: FretLayout) -> some View {
        ForEach(layout.visibleFrets, id: \.self) { fret in
            Text(fret == 0 ? "open" : "\(fret)")
                .font(.caption2.weight(.bold))
                .foregroundStyle(AppColors.mutedText.opacity(0.7))
                .position(x: noteX(fret, layout: layout), y: 14)
        }
    }

    private func inlays(boardHeight: CGFloat, layout: FretLayout) -> some View {
        ZStack(alignment: .topLeading) {
            ForEach([3, 5, 7, 9, 12, 15, 17, 19, 21, 24].filter { layout.contains(fret: $0) }, id: \.self) { fret in
                if fret == 12 || fret == 24 {
                    fretDot(fret: fret, offset: -18, boardHeight: boardHeight, layout: layout)
                    fretDot(fret: fret, offset: 18, boardHeight: boardHeight, layout: layout)
                } else {
                    fretDot(fret: fret, offset: 0, boardHeight: boardHeight, layout: layout)
                }
            }
        }
    }

    private func fretDot(fret: Int, offset: CGFloat, boardHeight: CGFloat, layout: FretLayout) -> some View {
        Circle()
            .fill(AppColors.inlay)
            .frame(width: 14, height: 14)
            .position(x: noteX(fret, layout: layout), y: boardHeight / 2 + offset)
    }

    private func strings(boardHeight: CGFloat, layout: FretLayout) -> some View {
        ForEach(displayedStrings.indices, id: \.self) { index in
            Rectangle()
                .fill(LinearGradient(colors: [.white.opacity(0.95), AppColors.string, .white.opacity(0.75)], startPoint: .top, endPoint: .bottom))
                .frame(width: layout.stringWidth(horizontalPadding: horizontalPadding), height: stringThickness(for: index))
                .shadow(color: AppColors.stringGlow.opacity(0.45), radius: 3, x: 0, y: 0)
                .position(x: layout.boardWidth / 2, y: stringY(index, boardHeight: boardHeight))
        }
    }

    private func markerViews(boardHeight: CGFloat, layout: FretLayout) -> some View {
        ForEach(markers.filter { layout.contains(fret: $0.position.fret) }) { marker in
            NoteMarker(label: marker.label, isRoot: marker.isRoot, isOpenString: marker.position.fret == 0)
                .position(x: noteX(marker.position.fret, layout: layout), y: stringY(marker.position.stringIndex, boardHeight: boardHeight))
        }
    }

    private func barreViews(boardHeight: CGFloat, layout: FretLayout) -> some View {
        ForEach(barres.filter { layout.contains(fret: $0.fret) }) { barre in
            let startIndex = min(barre.fromStringNumber, barre.toStringNumber) - 1
            let endIndex = max(barre.fromStringNumber, barre.toStringNumber) - 1
            if displayedStrings.indices.contains(startIndex), displayedStrings.indices.contains(endIndex) {
                let y1 = stringY(startIndex, boardHeight: boardHeight)
                let y2 = stringY(endIndex, boardHeight: boardHeight)
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .fill(AppColors.barre.opacity(0.86))
                    .frame(width: 22, height: abs(y2 - y1) + 30)
                    .shadow(color: AppColors.barre.opacity(0.35), radius: 7, x: 0, y: 0)
                    .position(x: noteX(barre.fret, layout: layout), y: (y1 + y2) / 2)
            }
        }
    }

    private func tapTargets(boardHeight: CGFloat, layout: FretLayout) -> some View {
        ForEach(displayedStrings.indices, id: \.self) { stringIndex in
            ForEach(layout.visibleFrets, id: \.self) { fret in
                let position = FretPosition(stringIndex: stringIndex, fret: fret)
                Button {
                    onTapPosition?(position)
                } label: {
                    Circle()
                        .fill(selectedPositions.contains(position) ? AppColors.noteMarker : Color.clear)
                        .overlay(
                            Circle()
                                .stroke(selectedPositions.contains(position) ? AppColors.rootText : Color.clear, lineWidth: 3)
                        )
                        .frame(width: 36, height: 36)
                }
                .buttonStyle(.plain)
                .position(x: noteX(fret, layout: layout), y: stringY(stringIndex, boardHeight: boardHeight))
            }
        }
    }

    func pitchClass(for position: FretPosition) -> Int {
        let string = displayedStrings[position.stringIndex]
        return (string.pitchClass + position.fret) % 12
    }

    private func stringY(_ index: Int, boardHeight: CGFloat) -> CGFloat {
        guard displayedStrings.count > 1 else { return boardHeight / 2 }
        let availableHeight = boardHeight - verticalPadding * 2
        return verticalPadding + CGFloat(index) * (availableHeight / CGFloat(displayedStrings.count - 1))
    }

    private func stringThickness(for displayedIndex: Int) -> CGFloat {
        CGFloat(displayedIndex + 1) * 0.9 + 1.8
    }

    private func noteX(_ fret: Int, layout: FretLayout) -> CGFloat {
        layout.noteX(fret, openStringWidth: openStringWidth, horizontalPadding: horizontalPadding)
    }
}

struct NoteMarker: View {
    let label: String
    let isRoot: Bool
    let isOpenString: Bool

    var body: some View {
        Text(label)
            .font(.system(size: isRoot ? 16 : 14, weight: .bold, design: .rounded))
            .foregroundStyle(isRoot ? AppColors.rootText : AppColors.noteText)
            .lineLimit(2)
            .multilineTextAlignment(.center)
            .minimumScaleFactor(0.65)
            .frame(width: isRoot ? 42 : 38, height: 34)
            .background(
                RoundedRectangle(cornerRadius: isRoot ? 9 : 17, style: .continuous)
                    .fill(AppColors.noteMarker)
            )
            .overlay(
                RoundedRectangle(cornerRadius: isRoot ? 9 : 17, style: .continuous)
                    .stroke(isOpenString ? AppColors.openStringStroke : .clear, lineWidth: 3)
            )
            .shadow(color: .black.opacity(0.28), radius: 4, x: 0, y: 2)
    }
}

private extension View {
    @ViewBuilder
    func closeSettingsOnSingleFingerDrag(_ action: (() -> Void)?) -> some View {
        if let action {
            highPriorityGesture(
                DragGesture(minimumDistance: 1)
                    .onChanged { value in
                        guard abs(value.translation.width) > 1 || abs(value.translation.height) > 1 else { return }
                        action()
                    },
                including: .all
            )
        } else {
            self
        }
    }
}
