import SwiftUI

struct FunctionalHarmonyView: View {
    let noteNames: [String]
    @State private var selectedRoot = 0
    @State private var keyMode: FunctionalKeyMode = .major
    @State private var chordKind: FunctionalChordKind = .triad
    @State private var chordCount = 4
    @State private var selectedDegrees = Array(repeating: 1, count: 8)

    var body: some View {
        ScrollView(.vertical) {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(HarmonyData.functional) { group in
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(group.title) (\(group.symbol))")
                                    .font(.title3.weight(.bold))
                                    .foregroundStyle(AppColors.primaryText)
                                Text(functionTransitions(for: group.symbol))
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(AppColors.mutedText)
                            }
                            .frame(width: 300, alignment: .leading)

                            ForEach(group.degrees, id: \.0) { degree, color in
                                DegreeChip(text: degree, color: color.color)
                            }
                        }
                    }
                }
                .padding(26)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppColors.panel.opacity(0.92), in: RoundedRectangle(cornerRadius: 10, style: .continuous))

                FunctionalProgressionBuilder(
                    noteNames: noteNames,
                    selectedRoot: $selectedRoot,
                    keyMode: $keyMode,
                    chordKind: $chordKind,
                    chordCount: $chordCount,
                    selectedDegrees: $selectedDegrees
                )
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.page)
    }

    private func functionTransitions(for symbol: String) -> String {
        switch symbol {
        case "T": "T -> S, T -> D"
        case "S": "S -> T, S -> D"
        case "D": "D -> T"
        default: ""
        }
    }
}

private enum FunctionalKeyMode: String, CaseIterable, Identifiable {
    case major
    case minor

    var id: String { rawValue }

    var title: String {
        switch self {
        case .major: "Мажор"
        case .minor: "Минор"
        }
    }

    var intervals: [Int] {
        switch self {
        case .major: [0, 2, 4, 5, 7, 9, 11]
        case .minor: [0, 2, 3, 5, 7, 8, 10]
        }
    }

    var qualities: [String] {
        switch self {
        case .major: ["", "m", "m", "", "", "m", "dim"]
        case .minor: ["m", "dim", "", "m", "m", "", ""]
        }
    }

    var seventhQualities: [String] {
        switch self {
        case .major: ["maj7", "m7", "m7", "maj7", "7", "m7", "m7b5"]
        case .minor: ["m7", "m7b5", "maj7", "m7", "m7", "maj7", "7"]
        }
    }

    var degreeTitles: [String] {
        switch self {
        case .major: ["I", "ii", "iii", "IV", "V", "vi", "vii°"]
        case .minor: ["i", "ii°", "III", "iv", "v", "VI", "VII"]
        }
    }
}

private enum FunctionalChordKind: String, CaseIterable, Identifiable {
    case triad
    case seventh

    var id: String { rawValue }

    var title: String {
        switch self {
        case .triad: "Трезвучие"
        case .seventh: "Септаккорд"
        }
    }
}

private enum ModalBuilderMode: String, CaseIterable, Identifiable {
    case dorian
    case phrygian
    case lydian
    case mixolydian
    case locrian

    var id: String { rawValue }

    var title: String {
        switch self {
        case .dorian: "Дорийский"
        case .phrygian: "Фригийский"
        case .lydian: "Лидийский"
        case .mixolydian: "Миксолидийский"
        case .locrian: "Локрийский"
        }
    }

    var intervals: [Int] {
        switch self {
        case .dorian: [0, 2, 3, 5, 7, 9, 10]
        case .phrygian: [0, 1, 3, 5, 7, 8, 10]
        case .lydian: [0, 2, 4, 6, 7, 9, 11]
        case .mixolydian: [0, 2, 4, 5, 7, 9, 10]
        case .locrian: [0, 1, 3, 5, 6, 8, 10]
        }
    }

    var cells: [(degree: String, chord: String, color: HarmonyColor)] {
        switch self {
        case .dorian: [("i", "m", .green), ("ii", "m", .green), ("III", "maj", .yellow), ("IV", "maj", .green), ("v", "m", .red), ("vi°", "dim", .red), ("VII", "maj", .red)]
        case .phrygian: [("i", "m", .green), ("II", "maj", .green), ("III", "maj", .yellow), ("iv", "m", .red), ("V°", "dim", .red), ("VI", "maj", .yellow), ("vii", "m", .green)]
        case .lydian: [("I", "maj", .green), ("II", "maj", .green), ("iii", "m", .yellow), ("iv°", "dim", .red), ("V", "maj", .red), ("vi", "m", .yellow), ("vii", "m", .green)]
        case .mixolydian: [("I", "maj", .green), ("ii", "m", .yellow), ("iii°", "dim", .red), ("IV", "maj", .red), ("v", "m", .green), ("vi", "m", .yellow), ("VII", "maj", .green)]
        case .locrian: [("i°", "dim", .red), ("II", "maj", .yellow), ("iii", "m", .green), ("iv", "m", .green), ("V", "maj", .red), ("VI", "maj", .yellow), ("vi", "m", .green)]
        }
    }

    var availableDegrees: [Int] {
        cells.enumerated().compactMap { index, cell in
            cell.color == .red ? nil : index + 1
        }
    }
}

private struct FunctionalProgressionBuilder: View {
    let noteNames: [String]
    @Binding var selectedRoot: Int
    @Binding var keyMode: FunctionalKeyMode
    @Binding var chordKind: FunctionalChordKind
    @Binding var chordCount: Int
    @Binding var selectedDegrees: [Int]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .center, spacing: 14) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Своя последовательность")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(AppColors.primaryText)
                    Text("Выбери тональность, длину и ступени")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppColors.mutedText)
                }

                Spacer()

                UIKitMenuPicker(title: "Тоника", selection: $selectedRoot, options: noteOptions)
                    .frame(width: 170, height: 40)
            }

            HStack(spacing: 12) {
                Picker("Лад", selection: $keyMode) {
                    ForEach(FunctionalKeyMode.allCases) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 220)

                Picker("Аккорды", selection: $chordCount) {
                    Text("4").tag(4)
                    Text("8").tag(8)
                }
                .pickerStyle(.segmented)
                .frame(width: 132)

                Picker("Тип", selection: $chordKind) {
                    ForEach(FunctionalChordKind.allCases) { kind in
                        Text(kind.title).tag(kind)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 230)

                Spacer()
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 4), alignment: .leading, spacing: 16) {
                ForEach(0..<chordCount, id: \.self) { index in
                    let degree = selectedDegrees[index]
                    DegreeSquarePicker(
                        index: index,
                        degree: degree,
                        function: functionTitle(for: degree),
                        degreeTitle: keyMode.degreeTitles[degree - 1],
                        chordName: chordName(for: degree),
                        color: functionColor(for: degree),
                        options: degreeOptions,
                        onSelect: { selectedDegrees[index] = $0 }
                    )
                }
            }
        }
        .padding(18)
        .background(AppColors.panel, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private var noteOptions: [MenuPickerItem<Int>] {
        noteNames.indices.map { MenuPickerItem(value: $0, title: noteNames[$0]) }
    }

    private var degreeOptions: [MenuPickerItem<Int>] {
        (1...7).map { degree in
            MenuPickerItem(value: degree, title: "\(degree) - \(keyMode.degreeTitles[degree - 1]) - \(functionTitle(for: degree))")
        }
    }

    private func chordName(for degree: Int) -> String {
        let index = max(0, min(degree - 1, 6))
        let pitch = (selectedRoot + keyMode.intervals[index]) % 12
        switch chordKind {
        case .triad:
            return "\(noteNames[pitch])\(keyMode.qualities[index])"
        case .seventh:
            return "\(noteNames[pitch])\(keyMode.seventhQualities[index])"
        }
    }

    private func functionTitle(for degree: Int) -> String {
        switch degree {
        case 1, 3, 6: "T"
        case 2, 4: "S"
        case 5: "D"
        case 7: "S/D"
        default: ""
        }
    }

    private func functionColor(for degree: Int) -> Color {
        switch degree {
        case 1, 4, 5: HarmonyColor.green.color
        case 2, 6, 7: HarmonyColor.yellow.color
        case 3: HarmonyColor.red.color
        default: AppColors.control
        }
    }
}

private struct DegreeSquarePicker: View {
    let index: Int
    let degree: Int
    let function: String
    let degreeTitle: String
    let chordName: String
    let color: Color
    let options: [MenuPickerItem<Int>]
    let onSelect: (Int) -> Void

    var body: some View {
        Menu {
            ForEach(options) { option in
                Button(option.title) {
                    onSelect(option.value)
                }
            }
        } label: {
            ZStack {
                VStack(spacing: 10) {
                    Text(chordName)
                        .font(.system(size: 42, weight: .black, design: .rounded))
                        .minimumScaleFactor(0.65)
                        .lineLimit(1)
                    Text("\(degree) / \(degreeTitle)")
                        .font(.title3.weight(.heavy))
                        .minimumScaleFactor(0.7)
                        .lineLimit(1)
                }
                .padding(.horizontal, 10)
                .foregroundStyle(.white)

                VStack {
                    Text(function)
                        .font(.title3.weight(.black))
                        .foregroundStyle(.white.opacity(0.82))
                    Spacer()
                }
                .padding(.top, 12)
            }
            .frame(maxWidth: .infinity)
            .aspectRatio(1, contentMode: .fit)
            .background(color.opacity(0.84), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
        .accessibilityLabel("\(index + 1): \(chordName), ступень \(degree)")
    }
}

struct ModalHarmonyView: View {
    let noteNames: [String]
    @State private var selectedRoot = 0
    @State private var selectedMode: ModalBuilderMode = .dorian
    @State private var chordKind: FunctionalChordKind = .triad
    @State private var chordCount = 4
    @State private var selectedDegrees = Array(repeating: 1, count: 8)

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
                                .background(modalCellBackground(row: row, cell: cell), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                            }
                        }
                    }
                    .padding(14)
                    .background(AppColors.panel, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                }

                ModalProgressionBuilder(
                    noteNames: noteNames,
                    selectedRoot: $selectedRoot,
                    selectedMode: $selectedMode,
                    chordKind: $chordKind,
                    chordCount: $chordCount,
                    selectedDegrees: $selectedDegrees
                )
            }
            .padding(18)
        }
        .background(AppColors.page)
    }

    private func modalCellBackground(row: ModalHarmonyRow, cell: (degree: String, chord: String, color: HarmonyColor)) -> Color {
        if row.title.hasPrefix("Ионийский") || row.title.hasPrefix("Эолийский") {
            return AppColors.control
        }
        return cell.color.color.opacity(cell.color == .neutral ? 0.18 : 0.55)
    }
}

private struct ModalProgressionBuilder: View {
    let noteNames: [String]
    @Binding var selectedRoot: Int
    @Binding var selectedMode: ModalBuilderMode
    @Binding var chordKind: FunctionalChordKind
    @Binding var chordCount: Int
    @Binding var selectedDegrees: [Int]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .center, spacing: 14) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Модальная последовательность")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(AppColors.primaryText)
                    Text("Красные ступени не предлагаются")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppColors.mutedText)
                }

                Spacer()

                UIKitMenuPicker(title: "Тоника", selection: $selectedRoot, options: noteOptions)
                    .frame(width: 170, height: 40)
            }

            HStack(spacing: 12) {
                UIKitMenuPicker(title: "Лад", selection: modeBinding, options: modeOptions)
                    .frame(width: 240, height: 40)

                Picker("Аккорды", selection: $chordCount) {
                    Text("4").tag(4)
                    Text("8").tag(8)
                }
                .pickerStyle(.segmented)
                .frame(width: 132)

                Picker("Тип", selection: $chordKind) {
                    ForEach(FunctionalChordKind.allCases) { kind in
                        Text(kind.title).tag(kind)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 230)

                Spacer()
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 4), alignment: .leading, spacing: 16) {
                ForEach(0..<chordCount, id: \.self) { index in
                    let degree = validDegree(selectedDegrees[index])
                    let cell = selectedMode.cells[degree - 1]
                    DegreeSquarePicker(
                        index: index,
                        degree: degree,
                        function: "",
                        degreeTitle: cell.degree,
                        chordName: chordName(for: degree),
                        color: cell.color.color,
                        options: degreeOptions,
                        onSelect: { selectedDegrees[index] = $0 }
                    )
                }
            }
        }
        .padding(18)
        .background(AppColors.panel, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private var noteOptions: [MenuPickerItem<Int>] {
        noteNames.indices.map { MenuPickerItem(value: $0, title: noteNames[$0]) }
    }

    private var modeOptions: [MenuPickerItem<ModalBuilderMode>] {
        ModalBuilderMode.allCases.map { MenuPickerItem(value: $0, title: $0.title) }
    }

    private var modeBinding: Binding<ModalBuilderMode> {
        Binding(
            get: { selectedMode },
            set: { newValue in
                selectedMode = newValue
                normalizeSelectedDegrees()
            }
        )
    }

    private var degreeOptions: [MenuPickerItem<Int>] {
        selectedMode.availableDegrees.map { degree in
            let cell = selectedMode.cells[degree - 1]
            return MenuPickerItem(value: degree, title: "\(degree) - \(cell.degree) - \(cell.chord)")
        }
    }

    private func validDegree(_ degree: Int) -> Int {
        selectedMode.availableDegrees.contains(degree) ? degree : selectedMode.availableDegrees[0]
    }

    private func normalizeSelectedDegrees() {
        for index in selectedDegrees.indices where !selectedMode.availableDegrees.contains(selectedDegrees[index]) {
            selectedDegrees[index] = selectedMode.availableDegrees[0]
        }
    }

    private func chordName(for degree: Int) -> String {
        let index = max(0, min(degree - 1, 6))
        let pitch = (selectedRoot + selectedMode.intervals[index]) % 12
        switch chordKind {
        case .triad:
            return "\(noteNames[pitch])\(triadSuffix(for: selectedMode.cells[index].chord))"
        case .seventh:
            return "\(noteNames[pitch])\(seventhSuffix(for: degree))"
        }
    }

    private func triadSuffix(for chord: String) -> String {
        switch chord {
        case "maj": ""
        case "m": "m"
        case "dim": "dim"
        default: chord
        }
    }

    private func seventhSuffix(for degree: Int) -> String {
        let index = max(0, min(degree - 1, 6))
        let third = interval(from: index, steps: 2)
        let fifth = interval(from: index, steps: 4)
        let seventh = interval(from: index, steps: 6)

        return switch (third, fifth, seventh) {
        case (4, 7, 11): "maj7"
        case (4, 7, 10): "7"
        case (3, 7, 10): "m7"
        case (3, 6, 10): "m7b5"
        case (3, 6, 9): "dim7"
        default: "7"
        }
    }

    private func interval(from index: Int, steps: Int) -> Int {
        let target = index + steps
        let octave = target / 7
        let wrappedIndex = target % 7
        return selectedMode.intervals[wrappedIndex] + (12 * octave) - selectedMode.intervals[index]
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
