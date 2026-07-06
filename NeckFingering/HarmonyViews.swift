import SwiftUI

struct FunctionalHarmonyView: View {
    var body: some View {
        ScrollView([.horizontal, .vertical]) {
            ZStack {
                ArrowCanvas()
                    .padding(.horizontal, 40)
                    .padding(.vertical, 24)

                VStack(alignment: .leading, spacing: 16) {
                    ForEach(HarmonyData.functional) { group in
                        HStack(spacing: 12) {
                            Text("\(group.title) (\(group.symbol))")
                                .font(.title3.weight(.bold))
                                .foregroundStyle(AppColors.primaryText)
                                .frame(width: 300, alignment: .leading)

                            ForEach(group.degrees, id: \.0) { degree, color in
                                DegreeChip(text: degree, color: color.color)
                            }
                        }
                    }
                }
                .padding(26)
                .background(AppColors.panel.opacity(0.92), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            .frame(minWidth: 760, minHeight: 360)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.page)
    }
}

private struct ArrowCanvas: View {
    var body: some View {
        Canvas { context, size in
            func arrow(from start: CGPoint, to end: CGPoint, color: Color) {
                var path = Path()
                path.move(to: start)
                path.addCurve(to: end, control1: CGPoint(x: start.x + 120, y: start.y - 100), control2: CGPoint(x: end.x - 120, y: end.y - 100))
                context.stroke(path, with: .color(color), style: StrokeStyle(lineWidth: 5, lineCap: .round))
            }

            arrow(from: CGPoint(x: size.width * 0.18, y: size.height * 0.28), to: CGPoint(x: size.width * 0.78, y: size.height * 0.47), color: HarmonyColor.green.color)
            arrow(from: CGPoint(x: size.width * 0.18, y: size.height * 0.28), to: CGPoint(x: size.width * 0.78, y: size.height * 0.66), color: HarmonyColor.green.color)
            arrow(from: CGPoint(x: size.width * 0.18, y: size.height * 0.47), to: CGPoint(x: size.width * 0.78, y: size.height * 0.28), color: HarmonyColor.blue.color)
            arrow(from: CGPoint(x: size.width * 0.18, y: size.height * 0.47), to: CGPoint(x: size.width * 0.78, y: size.height * 0.66), color: HarmonyColor.blue.color)
            arrow(from: CGPoint(x: size.width * 0.78, y: size.height * 0.66), to: CGPoint(x: size.width * 0.18, y: size.height * 0.28), color: HarmonyColor.red.color)
        }
    }
}

struct ModalHarmonyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                ForEach(HarmonyData.modalRows) { row in
                    VStack(alignment: .leading, spacing: 10) {
                        Text(row.title)
                            .font(.headline.weight(.bold))
                            .foregroundStyle(AppColors.primaryText)

                        HStack(spacing: 8) {
                            ForEach(row.cells, id: \.degree) { cell in
                                VStack(spacing: 5) {
                                    Text(cell.degree)
                                        .font(.headline.weight(.bold))
                                    Text(cell.chord)
                                        .font(.caption.weight(.semibold))
                                }
                                .foregroundStyle(AppColors.primaryText)
                                .frame(maxWidth: .infinity, minHeight: 54)
                                .background(cell.color.color.opacity(cell.color == .neutral ? 0.18 : 0.55), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                            }
                        }
                    }
                    .padding(14)
                    .background(AppColors.panel, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
            }
            .padding(18)
        }
        .background(AppColors.page)
    }
}

struct PopularHarmonyView: View {
    let scale: ScalePattern
    let noteNames: [String]

    var body: some View {
        ScrollView(.vertical) {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(scale.shortName)
                        .font(.title2.weight(.bold))
                        .foregroundStyle(AppColors.primaryText)
                    Text("Популярные последовательности")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppColors.mutedText)
                }

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 320), spacing: 14)], alignment: .leading, spacing: 14) {
                    ForEach(HarmonyData.popularProgressions(for: scale)) { progression in
                        PopularProgressionCard(progression: progression, scale: scale, noteNames: noteNames)
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.page)
    }
}

private struct PopularProgressionCard: View {
    let progression: PopularProgression
    let scale: ScalePattern
    let noteNames: [String]
    @State private var selectedRoot = -1

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center, spacing: 10) {
                Text(progression.category)
                    .font(.caption.weight(.black))
                    .foregroundStyle(AppColors.primaryText)
                    .padding(.horizontal, 10)
                    .frame(height: 26)
                    .background(AppColors.control, in: RoundedRectangle(cornerRadius: 8, style: .continuous))

                Spacer()

                PopularityMeter(value: progression.popularity)
            }

            UIKitMenuPicker(title: "Тоника", selection: $selectedRoot, options: tonicOptions)
                .frame(maxWidth: .infinity, minHeight: 40, maxHeight: 40)

            VStack(alignment: .leading, spacing: 6) {
                Text(progression.title)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(AppColors.primaryText)
                    .lineLimit(2)

                Text(progression.progressionText)
                    .font(.system(.subheadline, design: .rounded).weight(.heavy))
                    .foregroundStyle(AppColors.mutedText)
                    .lineLimit(2)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Array(displayedSteps.enumerated()), id: \.offset) { _, step in
                        ProgressionDegreeChip(text: step)
                            .frame(width: max(58, CGFloat(step.count * 13 + 28)), height: 38)
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 204, alignment: .topLeading)
        .background(AppColors.panel, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var tonicOptions: [MenuPickerItem<Int>] {
        [MenuPickerItem(value: -1, title: "Ступени")] + noteNames.indices.map { MenuPickerItem(value: $0, title: noteNames[$0]) }
    }

    private var displayedSteps: [String] {
        guard selectedRoot >= 0 else { return progression.degrees }
        return progression.degrees.map { chordName(for: $0, root: selectedRoot) }
    }

    private func chordName(for degree: String, root: Int) -> String {
        let parts = degree.split(separator: "/", maxSplits: 1).map(String.init)
        let chordPart = parts[0]

        if parts.count == 2, chordPart == "V", let targetPitch = pitch(for: parts[1], root: root) {
            return "\(noteNames[(targetPitch + 7) % 12])7"
        }

        guard let chord = chord(for: chordPart, root: root) else { return degree }
        guard parts.count == 2, let bassPitch = pitch(for: parts[1], root: root) else { return chord }
        return "\(chord)/\(noteNames[bassPitch])"
    }

    private func chord(for degree: String, root: Int) -> String? {
        guard let pitch = pitch(for: degree, root: root) else { return nil }
        let quality: String
        if degree.contains("°") {
            quality = "dim"
        } else if romanToken(from: degree).first?.isLowercase == true {
            quality = "m"
        } else {
            quality = ""
        }
        return "\(noteNames[pitch])\(quality)"
    }

    private func pitch(for degree: String, root: Int) -> Int? {
        let accidentalOffset = degree.prefix(while: { $0 == "b" || $0 == "#" }).reduce(0) { result, character in
            result + (character == "b" ? -1 : 1)
        }
        let token = romanToken(from: degree)

        if let degreeNumber = Int(token), (1...scale.intervals.count).contains(degreeNumber) {
            return (root + scale.intervals[degreeNumber - 1] + accidentalOffset + 120) % 12
        }

        let romanDegrees = ["I", "II", "III", "IV", "V", "VI", "VII"]
        guard let index = romanDegrees.firstIndex(of: token.uppercased()), scale.intervals.indices.contains(index) else { return nil }
        return (root + scale.intervals[index] + accidentalOffset + 120) % 12
    }

    private func romanToken(from degree: String) -> String {
        degree
            .trimmingCharacters(in: CharacterSet(charactersIn: "b#"))
            .replacingOccurrences(of: "°", with: "")
    }
}

private struct PopularityMeter: View {
    let value: Int

    var body: some View {
        HStack(spacing: 4) {
            ForEach(1...5, id: \.self) { index in
                Capsule()
                    .fill(index <= value ? AppColors.mutedText : AppColors.control)
                    .frame(width: 14, height: 6)
            }
        }
    }
}

private struct ProgressionDegreeChip: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.headline.weight(.black))
            .minimumScaleFactor(0.7)
            .lineLimit(1)
            .foregroundStyle(AppColors.primaryText)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(AppColors.control, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct DegreeChip: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.title3.weight(.black))
            .foregroundStyle(.white)
            .frame(width: 66, height: 44)
            .background(color, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}
