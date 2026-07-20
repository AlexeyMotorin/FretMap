import SwiftUI

struct FunctionalHarmonyView: View {
    let noteNames: [String]
    @ObservedObject var store: AppSettingsStore

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
                    selectedRoot: $store.functionalRoot,
                    keyMode: $store.functionalKeyMode,
                    chordKind: $store.functionalChordKind,
                    chordCount: $store.functionalChordCount,
                    selectedDegrees: $store.functionalSelectedDegrees,
                    selectedChordKinds: $store.functionalSelectedChordKinds
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

enum FunctionalKeyMode: String, CaseIterable, Identifiable, Codable {
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

enum FunctionalChordKind: String, CaseIterable, Identifiable, Codable {
    case triad
    case seventh
    case mixed

    var id: String { rawValue }

    var title: String {
        switch self {
        case .triad: "Трезвучие"
        case .seventh: "Септаккорд"
        case .mixed: "Смешанный"
        }
    }
}

enum ModalBuilderMode: String, CaseIterable, Identifiable, Codable {
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
    @Binding var selectedChordKinds: [FunctionalChordKind]
    @StateObject private var audioPlayer = ProgressionAudioPlayer()

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

                playbackButton {
                    audioPlayer.play(chords: playbackChords)
                }
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

                Picker("Тип", selection: chordKindBinding) {
                    ForEach(FunctionalChordKind.allCases) { kind in
                        Text(kind.title).tag(kind)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 330)

                Spacer()
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 4), alignment: .leading, spacing: 16) {
                ForEach(0..<chordCount, id: \.self) { index in
                    let degree = selectedDegrees[index]
                    ZStack(alignment: .topTrailing) {
                        DegreeSquarePicker(
                            index: index,
                            degree: degree,
                            function: functionTitle(for: degree),
                            degreeTitle: keyMode.degreeTitles[degree - 1],
                            chordName: chordName(for: degree, at: index),
                            color: functionColor(for: degree),
                            options: degreeOptions,
                            onSelect: { selectedDegrees[index] = $0 }
                        )

                        if chordKind == .mixed {
                            chordKindButton(at: index)
                                .padding(8)
                        }
                    }
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

    private var chordKindBinding: Binding<FunctionalChordKind> {
        Binding(
            get: { chordKind },
            set: { newValue in
                if newValue == .mixed, chordKind != .mixed {
                    selectedChordKinds = Array(repeating: chordKind, count: 8)
                }
                chordKind = newValue
            }
        )
    }

    private func selectedChordKind(at index: Int) -> FunctionalChordKind {
        chordKind == .mixed ? selectedChordKinds[index] : chordKind
    }

    private func chordName(for degree: Int, at position: Int) -> String {
        let index = max(0, min(degree - 1, 6))
        let pitch = (selectedRoot + keyMode.intervals[index]) % 12
        switch selectedChordKind(at: position) {
        case .triad:
            return "\(noteNames[pitch])\(keyMode.qualities[index])"
        case .seventh:
            return "\(noteNames[pitch])\(keyMode.seventhQualities[index])"
        case .mixed:
            return "\(noteNames[pitch])\(keyMode.qualities[index])"
        }
    }

    private var playbackChords: [PlaybackChord] {
        Array(selectedDegrees.prefix(chordCount)).enumerated().map { position, degree in
            let index = max(0, min(degree - 1, 6))
            let root = (selectedRoot + keyMode.intervals[index]) % 12
            let intervals = switch selectedChordKind(at: position) {
            case .triad:
                triadIntervals(for: keyMode.qualities[index])
            case .seventh:
                seventhIntervals(for: keyMode.seventhQualities[index])
            case .mixed:
                triadIntervals(for: keyMode.qualities[index])
            }
            return PlaybackChord(rootPitchClass: root, intervals: intervals)
        }
    }

    private func chordKindButton(at index: Int) -> some View {
        Button {
            selectedChordKinds[index] = selectedChordKinds[index] == .seventh ? .triad : .seventh
        } label: {
            Text(selectedChordKinds[index] == .seventh ? "7" : "3")
                .font(.caption.weight(.black))
                .foregroundStyle(.white)
                .frame(width: 30, height: 28)
                .background(.black.opacity(0.28), in: RoundedRectangle(cornerRadius: 7, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(selectedChordKinds[index] == .seventh ? "Септаккорд" : "Трезвучие")
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

    private func playbackButton(action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: audioPlayer.isPlaying ? "stop.fill" : "play.fill")
                .font(.system(size: 16, weight: .black))
                .foregroundStyle(AppColors.primaryText)
                .frame(width: 44, height: 40)
                .background(AppColors.control, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(audioPlayer.isPlaying ? "Остановить последовательность" : "Воспроизвести последовательность")
    }

    private func triadIntervals(for suffix: String) -> [Int] {
        switch suffix {
        case "m": [0, 3, 7]
        case "dim": [0, 3, 6]
        case "aug": [0, 4, 8]
        default: [0, 4, 7]
        }
    }

    private func seventhIntervals(for suffix: String) -> [Int] {
        switch suffix {
        case "maj7": [0, 4, 7, 11]
        case "m7": [0, 3, 7, 10]
        case "m7b5": [0, 3, 6, 10]
        case "dim7": [0, 3, 6, 9]
        default: [0, 4, 7, 10]
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
    @ObservedObject var store: AppSettingsStore

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
                    selectedRoot: $store.modalRoot,
                    selectedMode: $store.modalMode,
                    chordKind: $store.modalChordKind,
                    chordCount: $store.modalChordCount,
                    selectedDegrees: $store.modalSelectedDegrees,
                    selectedChordKinds: $store.modalSelectedChordKinds
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
    @Binding var selectedChordKinds: [FunctionalChordKind]
    @StateObject private var audioPlayer = ProgressionAudioPlayer()

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

                playbackButton {
                    audioPlayer.play(chords: playbackChords)
                }
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

                Picker("Тип", selection: chordKindBinding) {
                    ForEach(FunctionalChordKind.allCases) { kind in
                        Text(kind.title).tag(kind)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 330)

                Spacer()
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 4), alignment: .leading, spacing: 16) {
                ForEach(0..<chordCount, id: \.self) { index in
                    let degree = validDegree(selectedDegrees[index])
                    let cell = selectedMode.cells[degree - 1]
                    ZStack(alignment: .topTrailing) {
                        DegreeSquarePicker(
                            index: index,
                            degree: degree,
                            function: "",
                            degreeTitle: cell.degree,
                            chordName: chordName(for: degree, at: index),
                            color: cell.color.color,
                            options: degreeOptions,
                            onSelect: { selectedDegrees[index] = $0 }
                        )

                        if chordKind == .mixed {
                            chordKindButton(at: index)
                                .padding(8)
                        }
                    }
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

    private var chordKindBinding: Binding<FunctionalChordKind> {
        Binding(
            get: { chordKind },
            set: { newValue in
                if newValue == .mixed, chordKind != .mixed {
                    selectedChordKinds = Array(repeating: chordKind, count: 8)
                }
                chordKind = newValue
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

    private func selectedChordKind(at index: Int) -> FunctionalChordKind {
        chordKind == .mixed ? selectedChordKinds[index] : chordKind
    }

    private func chordName(for degree: Int, at position: Int) -> String {
        let index = max(0, min(degree - 1, 6))
        let pitch = (selectedRoot + selectedMode.intervals[index]) % 12
        switch selectedChordKind(at: position) {
        case .triad:
            return "\(noteNames[pitch])\(triadSuffix(for: selectedMode.cells[index].chord))"
        case .seventh:
            return "\(noteNames[pitch])\(seventhSuffix(for: degree))"
        case .mixed:
            return "\(noteNames[pitch])\(triadSuffix(for: selectedMode.cells[index].chord))"
        }
    }

    private var playbackChords: [PlaybackChord] {
        Array(selectedDegrees.prefix(chordCount)).enumerated().map { position, selectedDegree in
            let degree = validDegree(selectedDegree)
            let index = max(0, min(degree - 1, 6))
            let root = (selectedRoot + selectedMode.intervals[index]) % 12
            let intervals = switch selectedChordKind(at: position) {
            case .triad:
                triadIntervals(for: selectedMode.cells[index].chord)
            case .seventh:
                seventhIntervals(for: degree)
            case .mixed:
                triadIntervals(for: selectedMode.cells[index].chord)
            }
            return PlaybackChord(rootPitchClass: root, intervals: intervals)
        }
    }

    private func chordKindButton(at index: Int) -> some View {
        Button {
            selectedChordKinds[index] = selectedChordKinds[index] == .seventh ? .triad : .seventh
        } label: {
            Text(selectedChordKinds[index] == .seventh ? "7" : "3")
                .font(.caption.weight(.black))
                .foregroundStyle(.white)
                .frame(width: 30, height: 28)
                .background(.black.opacity(0.28), in: RoundedRectangle(cornerRadius: 7, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(selectedChordKinds[index] == .seventh ? "Септаккорд" : "Трезвучие")
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

    private func triadIntervals(for chord: String) -> [Int] {
        switch chord {
        case "m": [0, 3, 7]
        case "dim": [0, 3, 6]
        case "aug": [0, 4, 8]
        default: [0, 4, 7]
        }
    }

    private func seventhIntervals(for degree: Int) -> [Int] {
        let index = max(0, min(degree - 1, 6))
        return [
            0,
            interval(from: index, steps: 2),
            interval(from: index, steps: 4),
            interval(from: index, steps: 6)
        ]
    }

    private func playbackButton(action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: audioPlayer.isPlaying ? "stop.fill" : "play.fill")
                .font(.system(size: 16, weight: .black))
                .foregroundStyle(AppColors.primaryText)
                .frame(width: 44, height: 40)
                .background(AppColors.control, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(audioPlayer.isPlaying ? "Остановить последовательность" : "Воспроизвести последовательность")
    }

    private func interval(from index: Int, steps: Int) -> Int {
        let target = index + steps
        let octave = target / 7
        let wrappedIndex = target % 7
        return selectedMode.intervals[wrappedIndex] + (12 * octave) - selectedMode.intervals[index]
    }
}

enum PopularCollectionMode: String, CaseIterable, Identifiable, Codable {
    case popular
    case favorites

    var id: String { rawValue }

    var title: String {
        switch self {
        case .popular: "Популярные"
        case .favorites: "Избранное"
        }
    }
}

enum PopularSortMode: String, CaseIterable, Identifiable, Codable {
    case defaultOrder
    case ratingDescending

    var id: String { rawValue }

    var title: String {
        switch self {
        case .defaultOrder: "По умолчанию"
        case .ratingDescending: "По рейтингу"
        }
    }
}

struct PopularHarmonyView: View {
    let noteNames: [String]
    @ObservedObject var store: AppSettingsStore

    var body: some View {
        ScrollView(.vertical) {
            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .center, spacing: 12) {
                    Picker("Раздел", selection: $store.popularCollectionMode) {
                        ForEach(PopularCollectionMode.allCases) { mode in
                            Text(mode.title).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 270)

                    Spacer()

                    UIKitMenuPicker(
                        title: "Сортировка",
                        selection: $store.popularSortMode,
                        options: PopularSortMode.allCases.map {
                            MenuPickerItem(value: $0, title: $0.title)
                        }
                    )
                    .frame(width: 190, height: 40)

                    UIKitMenuPicker(title: "Тоника", selection: globalRootBinding, options: tonicOptions)
                        .frame(width: 168, height: 40)
                }

                if displayedProgressions.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "star")
                            .font(.system(size: 28, weight: .semibold))
                        Text("В избранном пока ничего нет")
                            .font(.headline.weight(.bold))
                    }
                    .foregroundStyle(AppColors.mutedText)
                    .frame(maxWidth: .infinity, minHeight: 220)
                } else {
                    LazyVGrid(
                        columns: [
                            GridItem(.flexible(minimum: 0), spacing: 24),
                            GridItem(.flexible(minimum: 0), spacing: 24)
                        ],
                        alignment: .leading,
                        spacing: 18
                    ) {
                        ForEach(displayedProgressions) { progression in
                            PopularProgressionCard(
                                progression: progression,
                                noteNames: noteNames,
                                globalRoot: store.popularGlobalRoot,
                                selectedRoot: popularRootBinding(for: progression.id),
                                seventhChordIndexes: popularSeventhIndexesBinding(for: progression.id),
                                rating: ratingBinding(for: progression),
                                isFavorite: favoriteBinding(for: progression.id)
                            )
                        }
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.page)
    }

    private var tonicOptions: [MenuPickerItem<Int>] {
        [MenuPickerItem(value: -1, title: "---")] + noteNames.indices.map { MenuPickerItem(value: $0, title: noteNames[$0]) }
    }

    private var displayedProgressions: [PopularProgression] {
        let all = HarmonyData.allPopularProgressions
        let filtered: [PopularProgression]
        switch store.popularCollectionMode {
        case .popular:
            filtered = all
        case .favorites:
            let favorites = Set(store.favoriteProgressionIDs)
            filtered = all.filter { favorites.contains($0.id) }
        }

        switch store.popularSortMode {
        case .defaultOrder:
            return filtered
        case .ratingDescending:
            return filtered.enumerated().sorted { left, right in
                let leftRating = store.popularRatings[left.element.id] ?? 3
                let rightRating = store.popularRatings[right.element.id] ?? 3
                return leftRating == rightRating ? left.offset < right.offset : leftRating > rightRating
            }.map(\.element)
        }
    }

    private var globalRootBinding: Binding<Int> {
        Binding(
            get: { store.popularGlobalRoot },
            set: { newValue in
                store.popularGlobalRoot = newValue
                store.popularProgressionRoots = [:]
            }
        )
    }

    private func popularRootBinding(for progressionID: String) -> Binding<Int> {
        Binding(
            get: { store.popularProgressionRoots[progressionID] ?? -1 },
            set: { store.popularProgressionRoots[progressionID] = $0 }
        )
    }

    private func popularSeventhIndexesBinding(for progressionID: String) -> Binding<[Int]> {
        Binding(
            get: { store.popularSeventhChordIndexes[progressionID] ?? [] },
            set: { store.popularSeventhChordIndexes[progressionID] = $0.sorted() }
        )
    }

    private func ratingBinding(for progression: PopularProgression) -> Binding<Int> {
        Binding(
            get: { store.popularRatings[progression.id] ?? 3 },
            set: { store.popularRatings[progression.id] = min(max($0, 1), 5) }
        )
    }

    private func favoriteBinding(for progressionID: String) -> Binding<Bool> {
        Binding(
            get: { store.favoriteProgressionIDs.contains(progressionID) },
            set: { isFavorite in
                var favorites = Set(store.favoriteProgressionIDs)
                if isFavorite {
                    favorites.insert(progressionID)
                } else {
                    favorites.remove(progressionID)
                }
                store.favoriteProgressionIDs = Array(favorites)
            }
        )
    }
}

private struct PopularProgressionCard: View {
    let progression: PopularProgression
    let noteNames: [String]
    let globalRoot: Int
    @Binding var selectedRoot: Int
    @Binding var seventhChordIndexes: [Int]
    @Binding var rating: Int
    @Binding var isFavorite: Bool
    @StateObject private var audioPlayer = ProgressionAudioPlayer()

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center, spacing: 10) {
                RatingMeter(value: $rating)

                Spacer()

                favoriteButton

                tonicMenu

                playbackButton
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(progression.title)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(AppColors.primaryText)
                    .lineLimit(2)

                Text(progression.progressionText)
                    .font(.system(.subheadline, design: .rounded).weight(.heavy))
                    .foregroundStyle(AppColors.mutedText)
                    .lineLimit(3)
            }
            .frame(height: 58, alignment: .topLeading)

            HStack(spacing: chordButtonSpacing) {
                ForEach(progression.bars.indices, id: \.self) { barIndex in
                    ForEach(progression.bars[barIndex].indices, id: \.self) { chordIndex in
                        let flatIndex = progression.flatIndex(
                            barIndex: barIndex,
                            chordIndex: chordIndex
                        )
                        Button {
                            toggleSeventh(at: flatIndex)
                        } label: {
                            Text(displayedChord(barIndex: barIndex, chordIndex: chordIndex))
                                .font(.system(size: chordButtonFontSize, weight: .black, design: .rounded))
                                .minimumScaleFactor(0.48)
                                .lineLimit(1)
                                .foregroundStyle(AppColors.primaryText)
                                .padding(.horizontal, chordButtonHorizontalPadding)
                                .frame(minWidth: 0, maxWidth: .infinity, minHeight: chordButtonHeight, maxHeight: chordButtonHeight)
                                .background(
                                    seventhChordIndexes.contains(flatIndex)
                                        ? AppColors.rootText.opacity(0.72)
                                        : AppColors.control,
                                    in: RoundedRectangle(cornerRadius: 8, style: .continuous)
                                )
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Изменить тип аккорда")

                        if chordIndex < progression.bars[barIndex].count - 1 {
                            Text("/")
                                .font(.caption.weight(.black))
                                .foregroundStyle(AppColors.mutedText)
                                .fixedSize()
                        }
                    }
                }
            }
            .frame(minWidth: 0, maxWidth: .infinity)
            .clipped()
        }
        .padding(16)
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 210, alignment: .topLeading)
        .background(AppColors.panel, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(AppColors.control.opacity(0.42), lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var scale: ScalePattern { progression.scale }

    private var chordCount: Int { progression.degrees.count }

    private var chordButtonSpacing: CGFloat {
        chordCount > 6 ? 4 : 8
    }

    private var chordButtonFontSize: CGFloat {
        switch chordCount {
        case 8...: 13
        case 6...7: 15
        default: 18
        }
    }

    private var chordButtonHeight: CGFloat {
        chordCount > 6 ? 40 : 44
    }

    private var chordButtonHorizontalPadding: CGFloat {
        chordCount > 6 ? 3 : 8
    }

    private var tonicOptions: [MenuPickerItem<Int>] {
        [MenuPickerItem(value: -1, title: "---")] + noteNames.indices.map { MenuPickerItem(value: $0, title: noteNames[$0]) }
    }

    private var tonicMenu: some View {
        Menu {
            ForEach(tonicOptions) { option in
                Button(option.title) {
                    selectedRoot = option.value
                }
            }
        } label: {
            Text(tonicLabel)
                .font(.system(.caption, design: .rounded).weight(.black))
                .foregroundStyle(AppColors.primaryText)
                .frame(width: 48, height: 38)
                .background(AppColors.control, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var tonicLabel: String {
        if selectedRoot >= 0 {
            return noteNames[selectedRoot]
        }
        if globalRoot >= 0 {
            return noteNames[globalRoot]
        }
        return "---"
    }

    private var effectiveRoot: Int? {
        if selectedRoot >= 0 {
            return selectedRoot
        }
        if globalRoot >= 0 {
            return globalRoot
        }
        return nil
    }

    private func displayedChord(barIndex: Int, chordIndex: Int) -> String {
        let degree = progression.bars[barIndex][chordIndex]
        guard let root = effectiveRoot else { return degree }
        let flatIndex = progression.flatIndex(barIndex: barIndex, chordIndex: chordIndex)
        return chordDescriptor(
            for: degree,
            root: root,
            isSeventh: seventhChordIndexes.contains(flatIndex)
        )?.name ?? degree
    }

    private var favoriteButton: some View {
        Button {
            isFavorite.toggle()
        } label: {
            Image(systemName: isFavorite ? "star.fill" : "star")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(isFavorite ? HarmonyColor.yellow.color : AppColors.primaryText)
                .frame(width: 40, height: 38)
                .background(AppColors.control, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isFavorite ? "Удалить из избранного" : "Добавить в избранное")
    }

    private var playbackChords: [PlaybackChord] {
        guard let root = effectiveRoot else { return [] }
        return progression.bars.enumerated().flatMap { barIndex, bar in
            bar.enumerated().compactMap { chordIndex, degree in
                let flatIndex = progression.flatIndex(
                    barIndex: barIndex,
                    chordIndex: chordIndex
                )
                guard let chord = chordDescriptor(
                    for: degree,
                    root: root,
                    isSeventh: seventhChordIndexes.contains(flatIndex)
                ) else { return nil }
                return PlaybackChord(
                    rootPitchClass: chord.rootPitchClass,
                    intervals: chord.intervals,
                    durationMultiplier: 1 / Double(max(bar.count, 1))
                )
            }
        }
    }

    private var playbackButton: some View {
        Button {
            audioPlayer.play(chords: playbackChords)
        } label: {
            Image(systemName: audioPlayer.isPlaying ? "stop.fill" : "play.fill")
                .font(.system(size: 15, weight: .black))
                .foregroundStyle(effectiveRoot == nil ? AppColors.mutedText : AppColors.primaryText)
                .frame(width: 40, height: 38)
                .background(AppColors.control, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(effectiveRoot == nil)
        .accessibilityLabel(audioPlayer.isPlaying ? "Остановить последовательность" : "Воспроизвести последовательность")
    }

    private func toggleSeventh(at index: Int) {
        var indexes = Set(seventhChordIndexes)
        if indexes.contains(index) {
            indexes.remove(index)
        } else {
            indexes.insert(index)
        }
        seventhChordIndexes = indexes.sorted()
    }

    private func chordDescriptor(for degree: String, root: Int, isSeventh: Bool) -> PopularChordDescriptor? {
        let parts = degree.split(separator: "/", maxSplits: 1).map(String.init)
        let chordPart = parts[0]

        if parts.count == 2,
           chordPart == "V",
           romanToken(from: parts[1]).first?.isLetter == true,
           let targetPitch = pitch(for: parts[1], root: root) {
            let chordRoot = (targetPitch + 7) % 12
            return PopularChordDescriptor(
                name: "\(noteNames[chordRoot])7",
                rootPitchClass: chordRoot,
                intervals: [0, 4, 7, 10]
            )
        }

        guard let chordRoot = pitch(for: chordPart, root: root) else { return nil }
        let triadIntervals = triadIntervals(for: chordPart)
        var intervals = triadIntervals
        if isSeventh {
            intervals.append(seventhInterval(for: chordPart))
        }

        let suffix = chordSuffix(for: intervals)
        var name = "\(noteNames[chordRoot])\(suffix)"
        if parts.count == 2, let bassPitch = pitch(for: parts[1], root: root) {
            name += "/\(noteNames[bassPitch])"
        }
        return PopularChordDescriptor(name: name, rootPitchClass: chordRoot, intervals: intervals)
    }

    private func triadIntervals(for degree: String) -> [Int] {
        if degree.contains("°") {
            return [0, 3, 6]
        }
        if romanToken(from: degree).first?.isLowercase == true {
            return [0, 3, 7]
        }
        return [0, 4, 7]
    }

    private func seventhInterval(for degree: String) -> Int {
        guard let index = degreeIndex(for: degree), scale.intervals.count == 7 else {
            return degree.contains("°") || romanToken(from: degree).first?.isLowercase == true ? 10 : 11
        }
        let target = index + 6
        let wrappedIndex = target % 7
        let octave = target / 7
        let rootInterval = scale.intervals[index]
        return scale.intervals[wrappedIndex] + octave * 12 - rootInterval
    }

    private func chordSuffix(for intervals: [Int]) -> String {
        switch intervals {
        case [0, 4, 7]: return ""
        case [0, 3, 7]: return "m"
        case [0, 3, 6]: return "dim"
        case [0, 4, 7, 11]: return "maj7"
        case [0, 4, 7, 10]: return "7"
        case [0, 3, 7, 10]: return "m7"
        case [0, 3, 6, 10]: return "m7b5"
        case [0, 3, 6, 9]: return "dim7"
        default: return intervals.count == 4 ? "7" : ""
        }
    }

    private func degreeIndex(for degree: String) -> Int? {
        let token = romanToken(from: degree)
        if let number = Int(token), (1...7).contains(number) {
            return number - 1
        }
        return ["I", "II", "III", "IV", "V", "VI", "VII"].firstIndex(of: token.uppercased())
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

private struct PopularChordDescriptor {
    let name: String
    let rootPitchClass: Int
    let intervals: [Int]
}

private struct RatingMeter: View {
    @Binding var value: Int

    var body: some View {
        HStack(spacing: 4) {
            ForEach(1...5, id: \.self) { index in
                Button {
                    value = index
                } label: {
                    Capsule()
                        .fill(index <= value ? ratingColor : AppColors.control)
                        .frame(width: 14, height: 6)
                        .frame(width: 28, height: 30)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Рейтинг \(index) из 5")
            }
        }
    }

    private var ratingColor: Color {
        switch value {
        case 1:
            Color(red: 0.43, green: 0.08, blue: 0.15)
        case 2:
            HarmonyColor.red.color
        case 4:
            HarmonyColor.yellow.color
        case 5:
            HarmonyColor.green.color
        default:
            AppColors.mutedText
        }
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
