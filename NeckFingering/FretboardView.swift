import SwiftUI

struct FretboardView: View {
    let tuning: TuningPreset
    let fretCount: Int
    let markers: [FretMarker]
    let selectedPositions: Set<FretPosition>
    let customMode: Bool
    let onTapPosition: ((FretPosition) -> Void)?
    let onSwipe: (() -> Void)?

    private let openStringWidth: CGFloat = 54
    private let fretWidth: CGFloat = 62
    private let verticalPadding: CGFloat = 36
    private let horizontalPadding: CGFloat = 20

    private var displayedStrings: [GuitarString] { Array(tuning.strings.reversed()) }
    private var boardWidth: CGFloat { openStringWidth + CGFloat(fretCount) * fretWidth + horizontalPadding * 2 }

    var body: some View {
        GeometryReader { proxy in
            let boardHeight = max(120, proxy.size.height)

            ScrollView(.horizontal) {
                ZStack(alignment: .topLeading) {
                    Rectangle()
                        .fill(AppColors.fretboard)
                        .overlay(boardTexture)
                        .frame(width: boardWidth, height: boardHeight)

                    fretLines(boardHeight: boardHeight)
                    fretNumbers
                    inlays(boardHeight: boardHeight)
                    strings(boardHeight: boardHeight)
                    markerViews(boardHeight: boardHeight)

                    if customMode {
                        tapTargets(boardHeight: boardHeight)
                    }
                }
                .frame(width: boardWidth, height: boardHeight)
                .padding(.horizontal, 12)
                .contentShape(Rectangle())
                .closeSettingsOnSingleFingerDrag(onSwipe)
            }
            .scrollIndicators(.hidden)
            .background(AppColors.fretboard)
            .frame(width: proxy.size.width, height: proxy.size.height, alignment: .topLeading)
            .contentShape(Rectangle())
            .closeSettingsOnSingleFingerDrag(onSwipe)
        }
        .background(AppColors.fretboard)
    }

    private var boardTexture: some View {
        LinearGradient(
            colors: [Color.white.opacity(0.04), Color.black.opacity(0.08), Color.white.opacity(0.03)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private func fretLines(boardHeight: CGFloat) -> some View {
        ZStack(alignment: .topLeading) {
            Rectangle()
                .fill(AppColors.nut)
                .frame(width: 12, height: boardHeight)
                .position(x: horizontalPadding + openStringWidth, y: boardHeight / 2)

            ForEach(1...fretCount, id: \.self) { fret in
                Rectangle()
                    .fill(LinearGradient(colors: [.white.opacity(0.85), .gray.opacity(0.55), .white.opacity(0.7)], startPoint: .leading, endPoint: .trailing))
                    .frame(width: fret % 12 == 0 ? 5 : 3, height: boardHeight)
                    .shadow(color: .black.opacity(0.35), radius: 2, x: 2, y: 0)
                    .position(x: fretX(fret), y: boardHeight / 2)
            }
        }
    }

    private var fretNumbers: some View {
        ForEach(0...fretCount, id: \.self) { fret in
            Text(fret == 0 ? "open" : "\(fret)")
                .font(.caption2.weight(.bold))
                .foregroundStyle(AppColors.mutedText.opacity(0.7))
                .position(x: noteX(fret), y: 14)
        }
    }

    private func inlays(boardHeight: CGFloat) -> some View {
        ZStack(alignment: .topLeading) {
            ForEach([3, 5, 7, 9, 12, 15, 17, 19, 21, 24].filter { $0 <= fretCount }, id: \.self) { fret in
                if fret == 12 || fret == 24 {
                    fretDot(fret: fret, offset: -18, boardHeight: boardHeight)
                    fretDot(fret: fret, offset: 18, boardHeight: boardHeight)
                } else {
                    fretDot(fret: fret, offset: 0, boardHeight: boardHeight)
                }
            }
        }
    }

    private func fretDot(fret: Int, offset: CGFloat, boardHeight: CGFloat) -> some View {
        Circle()
            .fill(AppColors.inlay)
            .frame(width: 14, height: 14)
            .position(x: noteX(fret), y: boardHeight / 2 + offset)
    }

    private func strings(boardHeight: CGFloat) -> some View {
        ForEach(displayedStrings.indices, id: \.self) { index in
            Rectangle()
                .fill(LinearGradient(colors: [.white.opacity(0.95), AppColors.string, .white.opacity(0.75)], startPoint: .top, endPoint: .bottom))
                .frame(width: boardWidth, height: stringThickness(for: index))
                .shadow(color: AppColors.stringGlow.opacity(0.45), radius: 3, x: 0, y: 0)
                .position(x: boardWidth / 2, y: stringY(index, boardHeight: boardHeight))
        }
    }

    private func markerViews(boardHeight: CGFloat) -> some View {
        ForEach(markers) { marker in
            NoteMarker(label: marker.label, isRoot: marker.isRoot, isOpenString: marker.position.fret == 0)
                .position(x: noteX(marker.position.fret), y: stringY(marker.position.stringIndex, boardHeight: boardHeight))
        }
    }

    private func tapTargets(boardHeight: CGFloat) -> some View {
        ForEach(displayedStrings.indices, id: \.self) { stringIndex in
            ForEach(0...fretCount, id: \.self) { fret in
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
                .position(x: noteX(fret), y: stringY(stringIndex, boardHeight: boardHeight))
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

    private func fretX(_ fret: Int) -> CGFloat {
        horizontalPadding + openStringWidth + CGFloat(fret) * fretWidth
    }

    private func noteX(_ fret: Int) -> CGFloat {
        fret == 0 ? horizontalPadding + openStringWidth / 2 : horizontalPadding + openStringWidth + (CGFloat(fret) - 0.5) * fretWidth
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
