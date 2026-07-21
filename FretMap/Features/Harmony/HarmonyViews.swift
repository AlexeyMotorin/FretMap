import SwiftUI
import UIKit

struct FunctionalHarmonyView: View {
    let noteNames: [String]
    @ObservedObject var store: AppSettingsStore
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    private var isPortrait: Bool { verticalSizeClass != .compact }

    var body: some View {
        GeometryReader { proxy in
            let horizontalPadding: CGFloat = isPortrait ? 16 : 18
            let contentWidth = max(0, proxy.size.width - horizontalPadding * 2)

            ScrollView(.vertical) {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 16) {
                        ForEach(HarmonyData.functional) { group in
                            Group {
                                if isPortrait {
                                    VStack(alignment: .leading, spacing: 10) {
                                        functionalGroupTitle(group)
                                        functionalDegreeChips(group)
                                    }
                                } else {
                                    HStack(spacing: 12) {
                                        functionalGroupTitle(group)
                                            .frame(width: 300, alignment: .leading)
                                        functionalDegreeChips(group)
                                    }
                                }
                            }
                        }
                    }
                    .padding(isPortrait ? 16 : 26)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(AppColors.panel.opacity(0.92), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

                    FunctionalProgressionBuilder(
                        noteNames: noteNames,
                        selectedRoot: $store.functionalRoot,
                        keyMode: $store.functionalKeyMode,
                        chordCount: $store.functionalChordCount,
                        selectedDegrees: $store.functionalSelectedDegrees,
                        selectedChordKinds: $store.functionalSelectedChordKinds,
                        tempoBPM: $store.harmonyTempoBPM,
                        onSave: { name in
                            store.savedHarmonyProgressions.append(
                                SavedHarmonyProgression(
                                    name: name,
                                    source: .functional,
                                    root: store.functionalRoot,
                                    functionalMode: store.functionalKeyMode,
                                    degrees: Array(store.functionalSelectedDegrees.prefix(store.functionalChordCount)),
                                    chordKinds: Array(store.functionalSelectedChordKinds.prefix(store.functionalChordCount))
                                )
                            )
                        }
                    )
                }
                .frame(width: contentWidth, alignment: .topLeading)
                .padding(.horizontal, horizontalPadding)
                .padding(.vertical, horizontalPadding)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.clear)
    }

    private func functionalGroupTitle(_ group: FunctionalHarmonyGroup) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(group.title) (\(group.symbol))")
                .font(isPortrait ? .headline.weight(.bold) : .title3.weight(.bold))
                .foregroundStyle(AppColors.primaryText)
            Text(functionTransitions(for: group.symbol))
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppColors.mutedText)
        }
    }

    private func functionalDegreeChips(_ group: FunctionalHarmonyGroup) -> some View {
        HStack(spacing: 8) {
            ForEach(group.degrees, id: \.0) { degree, color in
                DegreeChip(text: degree, color: color.color)
            }
        }
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

private struct FunctionalProgressionBuilder: View {
    let noteNames: [String]
    @Binding var selectedRoot: Int
    @Binding var keyMode: FunctionalKeyMode
    @Binding var chordCount: Int
    @Binding var selectedDegrees: [Int]
    @Binding var selectedChordKinds: [FunctionalChordKind]
    @Binding var tempoBPM: Double
    let onSave: (String) -> Void
    @StateObject private var audioPlayer = ProgressionAudioPlayer()
    @State private var isNamingProgression = false
    @State private var progressionName = ""
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    private var isPortrait: Bool { verticalSizeClass != .compact }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if isPortrait {
                VStack(alignment: .leading, spacing: 10) {
                    builderTitle
                    HStack(spacing: 10) {
                        UIKitMenuPicker(title: "Тоника", selection: $selectedRoot, options: noteOptions)
                            .frame(maxWidth: .infinity, minHeight: 40, maxHeight: 40)
                        playbackButton {
                            audioPlayer.play(chords: playbackChords, bpm: tempoBPM)
                        }
                        saveButton
                    }
                }
            } else {
                HStack(alignment: .center, spacing: 14) {
                    builderTitle
                        .frame(maxWidth: .infinity, alignment: .leading)
                    UIKitMenuPicker(title: "Тоника", selection: $selectedRoot, options: noteOptions)
                        .frame(width: 170, height: 40)
                    playbackButton {
                        audioPlayer.play(chords: playbackChords, bpm: tempoBPM)
                    }
                    saveButton
                }
            }

            if isPortrait {
                VStack(spacing: 10) {
                    keyModePicker
                    chordCountPicker
                }
            } else {
                HStack(spacing: 12) {
                    keyModePicker.frame(maxWidth: .infinity)
                    chordCountPicker.frame(width: 132)
                }
            }

            HarmonyTempoSlider(bpm: $tempoBPM)

            LazyVGrid(columns: progressionColumns, alignment: .leading, spacing: 16) {
                ForEach(0..<chordCount, id: \.self) { index in
                    let degree = selectedDegrees[index]
                    DegreeSquarePicker(
                        index: index,
                        degree: degree,
                        function: functionTitle(for: degree),
                        degreeTitle: keyMode.degreeTitles[degree - 1],
                        chordName: chordName(for: degree, at: index),
                        portraitChordFontSize: 22,
                        color: functionColor(for: degree),
                        options: degreeOptions,
                        onSelect: { option in
                            selectedDegrees[index] = option.degree
                            selectedChordKinds[index] = option.kind
                        }
                    )
                }
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.panel, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .clipped()
        .fullScreenCover(
            isPresented: $isNamingProgression,
            onDismiss: {
                AppOrientationController.setSupportedOrientations(.allButUpsideDown)
            }
        ) {
            ProgressionNameDialog(
                name: $progressionName,
                placeholder: "Например, Куплет",
                onCancel: closeNameDialog,
                onSave: saveNamedProgression
            )
            .background(TransparentPresentationBackground())
        }
    }

    private var builderTitle: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Своя последовательность")
                .font(.title3.weight(.bold))
                .foregroundStyle(AppColors.primaryText)
            Text("Выбери тональность, длину и ступени")
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppColors.mutedText)
        }
    }

    private var keyModePicker: some View {
        Picker("Лад", selection: $keyMode) {
            ForEach(FunctionalKeyMode.allCases) { mode in
                Text(mode.title).tag(mode)
            }
        }
        .pickerStyle(.segmented)
    }

    private var chordCountPicker: some View {
        Picker("Аккорды", selection: $chordCount) {
            Text("4").tag(4)
            Text("8").tag(8)
        }
        .pickerStyle(.segmented)
    }

    private var progressionColumns: [GridItem] {
        let spacing: CGFloat = isPortrait ? 8 : 16
        return Array(repeating: GridItem(.flexible(minimum: 0), spacing: spacing), count: 4)
    }

    private var noteOptions: [MenuPickerItem<Int>] {
        noteNames.indices.map { MenuPickerItem(value: $0, title: noteNames[$0]) }
    }

    private var degreeOptions: [MenuPickerItem<DegreeChordOption>] {
        (1...7).flatMap { degree in
            [FunctionalChordKind.triad, .seventh].map { kind in
                MenuPickerItem(
                    value: DegreeChordOption(degree: degree, kind: kind),
                    title: "\(keyMode.degreeTitles[degree - 1]) - \(chordName(for: degree, kind: kind))"
                )
            }
        }
    }

    private func selectedChordKind(at index: Int) -> FunctionalChordKind {
        selectedChordKinds[index] == .seventh ? .seventh : .triad
    }

    private func chordName(for degree: Int, at position: Int) -> String {
        chordName(for: degree, kind: selectedChordKind(at: position))
    }

    private func chordName(for degree: Int, kind: FunctionalChordKind) -> String {
        let index = max(0, min(degree - 1, 6))
        let pitch = (selectedRoot + keyMode.intervals[index]) % 12
        switch kind {
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

    private var saveButton: some View {
        Button {
            openNameDialog()
        } label: {
            Image(systemName: "square.and.arrow.down")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(AppColors.primaryText)
                .frame(width: 44, height: 40)
                .background(AppColors.control, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Сохранить в «Мои»")
    }

    private func openNameDialog() {
        AppOrientationController.setSupportedOrientations(.portrait)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            isNamingProgression = true
        }
    }

    private func closeNameDialog() {
        progressionName = ""
        isNamingProgression = false
        AppOrientationController.setSupportedOrientations(.allButUpsideDown)
    }

    private func saveNamedProgression() {
        let name = progressionName.trimmingCharacters(in: .whitespacesAndNewlines)
        onSave(name.isEmpty ? "Моя последовательность" : name)
        progressionName = ""
        isNamingProgression = false
        AppOrientationController.setSupportedOrientations(.allButUpsideDown)
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

private struct ProgressionNameDialog: View {
    @Binding var name: String
    let placeholder: String
    let onCancel: () -> Void
    let onSave: () -> Void
    @FocusState private var isNameFocused: Bool

    var body: some View {
        ZStack {
            Color.black.opacity(0.58)
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture(perform: cancel)

            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top, spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Сохранить последовательность")
                            .font(.headline.weight(.bold))
                            .foregroundStyle(AppColors.primaryText)
                        Text("Она появится во вкладке «Мои»")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(AppColors.mutedText)
                    }
                }

                TextField(
                    "",
                    text: $name,
                    prompt: Text(placeholder).foregroundColor(AppColors.mutedText)
                )
                .font(.body.weight(.semibold))
                .foregroundStyle(AppColors.primaryText)
                .textInputAutocapitalization(.sentences)
                .submitLabel(.done)
                .focused($isNameFocused)
                .onSubmit(save)
                .padding(.horizontal, 14)
                .frame(height: 46)
                .background(AppColors.control, in: RoundedRectangle(cornerRadius: 8, style: .continuous))

                HStack(spacing: 12) {
                    Button("Отмена", action: cancel)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(AppColors.primaryText)
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                        .background(AppColors.control, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .buttonStyle(.plain)

                    Button("Сохранить", action: save)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                        .background(AppColors.rootText, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .buttonStyle(.plain)
                }
            }
            .padding(18)
            .frame(maxWidth: 520)
            .background(AppColors.panel, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(AppColors.control, lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.35), radius: 18, y: 8)
            .padding(20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea(.container)
        .onAppear {
            isNameFocused = true
        }
    }

    private func cancel() {
        isNameFocused = false
        onCancel()
    }

    private func save() {
        isNameFocused = false
        onSave()
    }
}

private struct TransparentPresentationBackground: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear
        DispatchQueue.main.async {
            view.superview?.superview?.backgroundColor = .clear
        }
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        DispatchQueue.main.async {
            uiView.superview?.superview?.backgroundColor = .clear
        }
    }
}

struct ModalHarmonyView: View {
    let noteNames: [String]
    @ObservedObject var store: AppSettingsStore
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    private var isPortrait: Bool { verticalSizeClass != .compact }

    var body: some View {
        GeometryReader { proxy in
            let horizontalPadding: CGFloat = isPortrait ? 16 : 18
            let contentWidth = max(0, proxy.size.width - horizontalPadding * 2)

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
                        .padding(isPortrait ? 10 : 14)
                        .background(AppColors.panel, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }

                    ModalProgressionBuilder(
                        noteNames: noteNames,
                        selectedRoot: $store.modalRoot,
                        selectedMode: $store.modalMode,
                        chordCount: $store.modalChordCount,
                        selectedDegrees: $store.modalSelectedDegrees,
                        selectedChordKinds: $store.modalSelectedChordKinds,
                        tempoBPM: $store.harmonyTempoBPM,
                        onSave: { name in
                            store.savedHarmonyProgressions.append(
                                SavedHarmonyProgression(
                                    name: name,
                                    source: .modal,
                                    root: store.modalRoot,
                                    modalMode: store.modalMode,
                                    degrees: Array(store.modalSelectedDegrees.prefix(store.modalChordCount)),
                                    chordKinds: Array(store.modalSelectedChordKinds.prefix(store.modalChordCount))
                                )
                            )
                        }
                    )
                }
                .frame(width: contentWidth, alignment: .topLeading)
                .padding(.horizontal, horizontalPadding)
                .padding(.vertical, horizontalPadding)
            }
        }
        .background(Color.clear)
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
    @Binding var chordCount: Int
    @Binding var selectedDegrees: [Int]
    @Binding var selectedChordKinds: [FunctionalChordKind]
    @Binding var tempoBPM: Double
    let onSave: (String) -> Void
    @StateObject private var audioPlayer = ProgressionAudioPlayer()
    @State private var isNamingProgression = false
    @State private var progressionName = ""
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    private var isPortrait: Bool { verticalSizeClass != .compact }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if isPortrait {
                VStack(alignment: .leading, spacing: 10) {
                    builderTitle
                    HStack(spacing: 10) {
                        UIKitMenuPicker(title: "Тоника", selection: $selectedRoot, options: noteOptions)
                            .frame(maxWidth: .infinity, minHeight: 40, maxHeight: 40)
                        playbackButton {
                            audioPlayer.play(chords: playbackChords, bpm: tempoBPM)
                        }
                        saveButton
                    }
                }
            } else {
                HStack(alignment: .center, spacing: 14) {
                    builderTitle
                        .frame(maxWidth: .infinity, alignment: .leading)
                    UIKitMenuPicker(title: "Тоника", selection: $selectedRoot, options: noteOptions)
                        .frame(width: 170, height: 40)
                    playbackButton {
                        audioPlayer.play(chords: playbackChords, bpm: tempoBPM)
                    }
                    saveButton
                }
            }

            if isPortrait {
                VStack(spacing: 10) {
                    UIKitMenuPicker(title: "Лад", selection: modeBinding, options: modeOptions)
                        .frame(maxWidth: .infinity, minHeight: 40, maxHeight: 40)
                    chordCountPicker
                }
            } else {
                HStack(spacing: 12) {
                    UIKitMenuPicker(title: "Лад", selection: modeBinding, options: modeOptions)
                        .frame(maxWidth: .infinity, minHeight: 40, maxHeight: 40)
                    chordCountPicker.frame(width: 132)
                }
            }

            HarmonyTempoSlider(bpm: $tempoBPM)

            LazyVGrid(columns: progressionColumns, alignment: .leading, spacing: 16) {
                ForEach(0..<chordCount, id: \.self) { index in
                    let degree = validDegree(selectedDegrees[index])
                    let cell = selectedMode.cells[degree - 1]
                    DegreeSquarePicker(
                        index: index,
                        degree: degree,
                        function: "",
                        degreeTitle: cell.degree,
                        chordName: chordName(for: degree, at: index),
                        color: cell.color.color,
                        options: degreeOptions,
                        onSelect: { option in
                            selectedDegrees[index] = option.degree
                            selectedChordKinds[index] = option.kind
                        }
                    )
                }
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.panel, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .clipped()
        .fullScreenCover(
            isPresented: $isNamingProgression,
            onDismiss: {
                AppOrientationController.setSupportedOrientations(.allButUpsideDown)
            }
        ) {
            ProgressionNameDialog(
                name: $progressionName,
                placeholder: "Например, Припев",
                onCancel: closeNameDialog,
                onSave: saveNamedProgression
            )
            .background(TransparentPresentationBackground())
        }
    }

    private var builderTitle: some View {
        Text("Модальная последовательность")
            .font(.title3.weight(.bold))
            .foregroundStyle(AppColors.primaryText)
    }

    private var chordCountPicker: some View {
        Picker("Аккорды", selection: $chordCount) {
            Text("4").tag(4)
            Text("8").tag(8)
        }
        .pickerStyle(.segmented)
    }

    private var progressionColumns: [GridItem] {
        let spacing: CGFloat = isPortrait ? 8 : 16
        return Array(repeating: GridItem(.flexible(minimum: 0), spacing: spacing), count: 4)
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

    private var degreeOptions: [MenuPickerItem<DegreeChordOption>] {
        (1...7).flatMap { degree in
            let degreeTitle = selectedMode.cells[degree - 1].degree
            return [FunctionalChordKind.triad, .seventh].map { kind in
                MenuPickerItem(
                    value: DegreeChordOption(degree: degree, kind: kind),
                    title: "\(degreeTitle) - \(chordName(for: degree, kind: kind))"
                )
            }
        }
    }

    private func validDegree(_ degree: Int) -> Int {
        min(max(degree, 1), 7)
    }

    private func normalizeSelectedDegrees() {
        for index in selectedDegrees.indices {
            selectedDegrees[index] = validDegree(selectedDegrees[index])
        }
    }

    private func selectedChordKind(at index: Int) -> FunctionalChordKind {
        selectedChordKinds[index] == .seventh ? .seventh : .triad
    }

    private func chordName(for degree: Int, at position: Int) -> String {
        chordName(for: degree, kind: selectedChordKind(at: position))
    }

    private func chordName(for degree: Int, kind: FunctionalChordKind) -> String {
        let index = max(0, min(degree - 1, 6))
        let pitch = (selectedRoot + selectedMode.intervals[index]) % 12
        switch kind {
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

    private var saveButton: some View {
        Button {
            openNameDialog()
        } label: {
            Image(systemName: "square.and.arrow.down")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(AppColors.primaryText)
                .frame(width: 44, height: 40)
                .background(AppColors.control, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Сохранить в «Мои»")
    }

    private func openNameDialog() {
        AppOrientationController.setSupportedOrientations(.portrait)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            isNamingProgression = true
        }
    }

    private func closeNameDialog() {
        progressionName = ""
        isNamingProgression = false
        AppOrientationController.setSupportedOrientations(.allButUpsideDown)
    }

    private func saveNamedProgression() {
        let name = progressionName.trimmingCharacters(in: .whitespacesAndNewlines)
        onSave(name.isEmpty ? "Моя последовательность" : name)
        progressionName = ""
        isNamingProgression = false
        AppOrientationController.setSupportedOrientations(.allButUpsideDown)
    }

    private func interval(from index: Int, steps: Int) -> Int {
        let target = index + steps
        let octave = target / 7
        let wrappedIndex = target % 7
        return selectedMode.intervals[wrappedIndex] + (12 * octave) - selectedMode.intervals[index]
    }
}

struct PopularHarmonyView: View {
    let noteNames: [String]
    @ObservedObject var store: AppSettingsStore
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    private var isPortrait: Bool { verticalSizeClass != .compact }

    var body: some View {
        Group {
            if displayedProgressions.isEmpty {
                VStack(alignment: .leading, spacing: 18) {
                    popularControls
                    tempoSlider
                    favoriteEmptyState
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .offset(y: isPortrait ? -80 : 0)
                }
                .padding(.horizontal, isPortrait ? 16 : 12)
                .padding(.vertical, 18)
            } else {
                ScrollViewReader { scrollProxy in
                    ScrollView(.vertical) {
                        VStack(alignment: .leading, spacing: 18) {
                            Color.clear
                                .frame(height: 0)
                                .id("popular-harmony-top")

                            popularControls
                            tempoSlider

                            LazyVGrid(
                                columns: progressionColumns,
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
                                        slashChordConfigurations: slashConfigurationsBinding(for: progression.id),
                                        rating: ratingBinding(for: progression),
                                        tempoBPM: store.harmonyTempoBPM,
                                        action: .favorite(favoriteBinding(for: progression.id))
                                    )
                                }
                            }

                            Spacer(minLength: 0)
                        }
                        .padding(.horizontal, isPortrait ? 16 : 12)
                        .padding(.vertical, 18)
                    }
                    .onAppear {
                        scrollProxy.scrollTo("popular-harmony-top", anchor: .top)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.clear)
    }

    @ViewBuilder
    private var popularControls: some View {
        if isPortrait {
            VStack(spacing: 10) {
                collectionPicker
                HStack(spacing: 10) {
                    sortPicker
                    tonicPicker
                }
            }
        } else {
            HStack(alignment: .center, spacing: 12) {
                HStack {
                    Spacer(minLength: 0)
                    collectionPicker.frame(width: 270)
                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity)

                sortPicker.frame(width: 190)
                tonicPicker.frame(width: 168)
            }
        }
    }

    private var tempoSlider: some View {
        HarmonyTempoSlider(bpm: $store.harmonyTempoBPM)
            .frame(maxWidth: isPortrait ? .infinity : 420)
    }

    private var favoriteEmptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "star")
                .font(.system(size: 28, weight: .semibold))
            Text("В избранном пока ничего нет")
                .font(.headline.weight(.bold))
                .multilineTextAlignment(.center)
        }
        .foregroundStyle(AppColors.mutedText)
    }

    private var collectionPicker: some View {
        Picker("Раздел", selection: $store.popularCollectionMode) {
            ForEach(PopularCollectionMode.allCases) { mode in
                if isPortrait {
                    Image(systemName: mode == .popular ? "flame.fill" : "star.fill")
                        .accessibilityLabel(mode.title)
                        .tag(mode)
                } else {
                    Text(mode.title).tag(mode)
                }
            }
        }
        .pickerStyle(.segmented)
    }

    private var sortPicker: some View {
        UIKitMenuPicker(
            title: "Сортировка",
            selection: $store.popularSortMode,
            options: PopularSortMode.allCases.map {
                MenuPickerItem(value: $0, title: $0.title)
            },
            displaysTitle: false
        )
        .frame(maxWidth: .infinity, minHeight: 40, maxHeight: 40)
    }

    private var tonicPicker: some View {
        UIKitMenuPicker(title: "Тоника", selection: globalRootBinding, options: tonicOptions)
            .frame(maxWidth: .infinity, minHeight: 40, maxHeight: 40)
    }

    private var progressionColumns: [GridItem] {
        Array(
            repeating: GridItem(.flexible(minimum: 0), spacing: 12),
            count: isPortrait ? 1 : 2
        )
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

    private func slashConfigurationsBinding(
        for progressionID: String
    ) -> Binding<[Int: PopularSlashChordConfiguration]> {
        Binding(
            get: { store.popularSlashChordConfigurations[progressionID] ?? [:] },
            set: { store.popularSlashChordConfigurations[progressionID] = $0 }
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

struct SavedHarmonyView: View {
    let noteNames: [String]
    @ObservedObject var store: AppSettingsStore
    @State private var isCreatingProgression = false
    @State private var progressionPendingDeletion: SavedHarmonyProgression?
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    private var isPortrait: Bool { verticalSizeClass != .compact }

    var body: some View {
        Group {
            if store.savedHarmonyProgressions.isEmpty {
                VStack(alignment: .leading, spacing: 18) {
                    savedHeader
                    tempoSlider
                    savedEmptyState
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .offset(y: isPortrait ? -80 : 0)
                }
                .padding(.horizontal, isPortrait ? 16 : 12)
                .padding(.vertical, 18)
            } else {
                ScrollView(.vertical) {
                    VStack(alignment: .leading, spacing: 18) {
                        savedHeader
                        tempoSlider
                        savedProgressionGrid
                    }
                    .padding(.horizontal, isPortrait ? 16 : 12)
                    .padding(.vertical, 18)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.clear)
        .fullScreenCover(isPresented: $isCreatingProgression) {
            SavedHarmonyEditor(noteNames: noteNames, store: store)
        }
        .alert(
            "Удалить последовательность?",
            isPresented: deletionAlertBinding,
            presenting: progressionPendingDeletion
        ) { progression in
            Button("Удалить", role: .destructive) {
                store.savedHarmonyProgressions.removeAll { $0.id == progression.id }
                progressionPendingDeletion = nil
            }
            Button("Отмена", role: .cancel) {
                progressionPendingDeletion = nil
            }
        } message: { progression in
            Text("«\(progression.name)» будет удалена без возможности восстановления.")
        }
    }

    private var savedHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Мои последовательности")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(AppColors.primaryText)
                Text("Сохранённые идеи из функциональной и модальной гармонии")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppColors.mutedText)
            }

            Spacer()

            Button {
                isCreatingProgression = true
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(AppColors.primaryText)
                    .frame(width: 44, height: 40)
                    .background(AppColors.control, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Создать последовательность")
        }
    }

    private var tempoSlider: some View {
        HarmonyTempoSlider(bpm: $store.harmonyTempoBPM)
            .frame(maxWidth: isPortrait ? .infinity : 420)
    }

    private var savedEmptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "music.note.list")
                .font(.system(size: 30, weight: .semibold))
            Text("Сохранённых последовательностей пока нет")
                .font(.headline.weight(.bold))
                .multilineTextAlignment(.center)
        }
        .foregroundStyle(AppColors.mutedText)
    }

    private var savedProgressionGrid: some View {
        LazyVGrid(
            columns: Array(
                repeating: GridItem(.flexible(minimum: 0), spacing: 12),
                count: isPortrait ? 1 : 2
            ),
            alignment: .leading,
            spacing: 18
        ) {
            ForEach(store.savedHarmonyProgressions) { saved in
                PopularProgressionCard(
                    progression: saved.popularProgression,
                    noteNames: noteNames,
                    globalRoot: -1,
                    selectedRoot: savedRootBinding(for: saved.id),
                    seventhChordIndexes: savedSeventhIndexesBinding(for: saved.id),
                    slashChordConfigurations: .constant([:]),
                    rating: savedRatingBinding(for: saved.id),
                    tempoBPM: store.harmonyTempoBPM,
                    action: .delete {
                        progressionPendingDeletion = saved
                    }
                )
            }
        }
    }

    private var deletionAlertBinding: Binding<Bool> {
        Binding(
            get: { progressionPendingDeletion != nil },
            set: { isPresented in
                if !isPresented {
                    progressionPendingDeletion = nil
                }
            }
        )
    }

    private func savedRootBinding(for id: String) -> Binding<Int> {
        Binding(
            get: { savedProgression(id: id)?.root ?? 0 },
            set: { newValue in
                updateSavedProgression(id: id) { $0.root = newValue }
            }
        )
    }

    private func savedSeventhIndexesBinding(for id: String) -> Binding<[Int]> {
        Binding(
            get: { savedProgression(id: id)?.seventhChordIndexes ?? [] },
            set: { newIndexes in
                updateSavedProgression(id: id) { progression in
                    let indexes = Set(newIndexes)
                    progression.chordKinds = progression.degrees.indices.map {
                        indexes.contains($0) ? .seventh : .triad
                    }
                }
            }
        )
    }

    private func savedRatingBinding(for id: String) -> Binding<Int> {
        Binding(
            get: { savedProgression(id: id)?.rating ?? 3 },
            set: { newValue in
                updateSavedProgression(id: id) {
                    $0.rating = min(max(newValue, 1), 5)
                }
            }
        )
    }

    private func savedProgression(id: String) -> SavedHarmonyProgression? {
        store.savedHarmonyProgressions.first { $0.id == id }
    }

    private func updateSavedProgression(
        id: String,
        update: (inout SavedHarmonyProgression) -> Void
    ) {
        guard let index = store.savedHarmonyProgressions.firstIndex(where: { $0.id == id }) else { return }
        update(&store.savedHarmonyProgressions[index])
    }
}

private struct SavedHarmonyEditor: View {
    enum EditorMode: String, CaseIterable, Identifiable {
        case functional
        case modal

        var id: String { rawValue }

        var title: String {
            switch self {
            case .functional: "Функциональная"
            case .modal: "Модальная"
            }
        }
    }

    let noteNames: [String]
    @ObservedObject var store: AppSettingsStore
    @Environment(\.dismiss) private var dismiss
    @State private var editorMode: EditorMode = .functional
    @State private var functionalRoot = 0
    @State private var functionalMode: FunctionalKeyMode = .major
    @State private var functionalCount = 4
    @State private var functionalDegrees = Array(repeating: 1, count: 8)
    @State private var functionalKinds = Array(repeating: FunctionalChordKind.triad, count: 8)
    @State private var modalRoot = 0
    @State private var modalMode: ModalBuilderMode = .dorian
    @State private var modalCount = 4
    @State private var modalDegrees = Array(repeating: 1, count: 8)
    @State private var modalKinds = Array(repeating: FunctionalChordKind.triad, count: 8)

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 16) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(AppColors.primaryText)
                        .frame(width: 44, height: 40)
                        .background(AppColors.control, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .buttonStyle(.plain)

                Picker("Тип гармонии", selection: $editorMode) {
                    ForEach(EditorMode.allCases) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 460)

                Spacer()
            }
            .padding(14)
            .background(AppColors.panel)

            ScrollView(.vertical) {
                Group {
                    switch editorMode {
                    case .functional:
                        FunctionalProgressionBuilder(
                            noteNames: noteNames,
                            selectedRoot: $functionalRoot,
                            keyMode: $functionalMode,
                            chordCount: $functionalCount,
                            selectedDegrees: $functionalDegrees,
                            selectedChordKinds: $functionalKinds,
                            tempoBPM: $store.harmonyTempoBPM,
                            onSave: saveFunctional
                        )
                    case .modal:
                        ModalProgressionBuilder(
                            noteNames: noteNames,
                            selectedRoot: $modalRoot,
                            selectedMode: $modalMode,
                            chordCount: $modalCount,
                            selectedDegrees: $modalDegrees,
                            selectedChordKinds: $modalKinds,
                            tempoBPM: $store.harmonyTempoBPM,
                            onSave: saveModal
                        )
                    }
                }
                .padding(18)
            }
        }
        .background(AppBackgroundView().allowsHitTesting(false))
    }

    private func saveFunctional(name: String) {
        store.savedHarmonyProgressions.append(
            SavedHarmonyProgression(
                name: name,
                source: .functional,
                root: functionalRoot,
                functionalMode: functionalMode,
                degrees: Array(functionalDegrees.prefix(functionalCount)),
                chordKinds: Array(functionalKinds.prefix(functionalCount))
            )
        )
        dismiss()
    }

    private func saveModal(name: String) {
        store.savedHarmonyProgressions.append(
            SavedHarmonyProgression(
                name: name,
                source: .modal,
                root: modalRoot,
                modalMode: modalMode,
                degrees: Array(modalDegrees.prefix(modalCount)),
                chordKinds: Array(modalKinds.prefix(modalCount))
            )
        )
        dismiss()
    }

}

private enum ProgressionCardAction {
    case favorite(Binding<Bool>)
    case delete(() -> Void)
}

private struct PopularProgressionCard: View {
    let progression: PopularProgression
    let noteNames: [String]
    let globalRoot: Int
    @Binding var selectedRoot: Int
    @Binding var seventhChordIndexes: [Int]
    @Binding var slashChordConfigurations: [Int: PopularSlashChordConfiguration]
    @Binding var rating: Int
    let tempoBPM: Double
    let action: ProgressionCardAction
    @StateObject private var audioPlayer = ProgressionAudioPlayer()

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center, spacing: 10) {
                RatingMeter(value: $rating)

                Spacer()

                actionButton

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
                    if progression.bars[barIndex].count == 2 {
                        slashChordMenu(barIndex: barIndex)
                    } else {
                        singleChordButton(barIndex: barIndex)
                    }
                }
            }
            .frame(minWidth: 0, maxWidth: .infinity)
        }
        .padding(16)
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 210, alignment: .topLeading)
        .background {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(AppColors.panel)

                if rating != 3 {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(progressionRatingColor(for: rating).opacity(cardRatingTintOpacity))
                }
            }
        }
    }

    private var scale: ScalePattern { progression.scale }

    private var chordCount: Int { progression.bars.count }

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

    private var cardRatingTintOpacity: Double {
        rating <= 2 ? 0.24 : 0.18
    }

    private func singleChordButton(barIndex: Int) -> some View {
        let flatIndex = progression.flatIndex(barIndex: barIndex, chordIndex: 0)
        let isSeventh = seventhChordIndexes.contains(flatIndex)

        return Text(displayedChord(barIndex: barIndex, chordIndex: 0))
            .font(.system(size: chordButtonFontSize, weight: .black, design: .rounded))
            .minimumScaleFactor(0.48)
            .lineLimit(1)
            .foregroundStyle(AppColors.primaryText)
            .padding(.horizontal, chordButtonHorizontalPadding)
            .frame(minWidth: 0, maxWidth: .infinity, minHeight: chordButtonHeight, maxHeight: chordButtonHeight)
            .background(
                isSeventh ? AppColors.rootText.opacity(0.72) : AppColors.control,
                in: RoundedRectangle(cornerRadius: 8, style: .continuous)
            )
            .contentShape(Rectangle())
            .onTapGesture {
                toggleSeventh(at: flatIndex)
            }
            .accessibilityAddTraits(.isButton)
            .accessibilityLabel("Изменить тип аккорда")
            .accessibilityAction {
                toggleSeventh(at: flatIndex)
            }
    }

    private func slashChordMenu(barIndex: Int) -> some View {
        let configuration = slashConfiguration(for: barIndex)

        return Menu {
            ForEach(PopularSlashChordConfiguration.allCases) { option in
                Button {
                    setSlashConfiguration(option, for: barIndex)
                } label: {
                    if option == configuration {
                        Label(
                            slashOptionTitle(for: barIndex, configuration: option),
                            systemImage: "checkmark"
                        )
                    } else {
                        Text(slashOptionTitle(for: barIndex, configuration: option))
                    }
                }
            }
        } label: {
            Text(slashOptionTitle(for: barIndex, configuration: configuration))
                .font(.system(size: chordButtonFontSize, weight: .black, design: .rounded))
                .minimumScaleFactor(0.42)
                .lineLimit(1)
                .foregroundStyle(AppColors.primaryText)
                .padding(.horizontal, chordButtonHorizontalPadding)
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: chordButtonHeight, maxHeight: chordButtonHeight)
                .background(
                    configuration == .triadTriad
                        ? AppColors.control
                        : AppColors.rootText.opacity(0.72),
                    in: RoundedRectangle(cornerRadius: 8, style: .continuous)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Выбрать типы аккордов в такте")
    }

    private func slashOptionTitle(
        for barIndex: Int,
        configuration: PopularSlashChordConfiguration
    ) -> String {
        let degrees = progression.bars[barIndex]
        guard degrees.count == 2 else { return degrees.joined(separator: " / ") }

        var names: [String] = []
        if configuration.firstIsActive {
            names.append(
                chordName(
                    for: degrees[0],
                    isSeventh: configuration.firstIsSeventh
                )
            )
        }
        if configuration.secondIsActive {
            names.append(
                chordName(
                    for: degrees[1],
                    isSeventh: configuration.secondIsSeventh
                )
            )
        }
        return names.joined(separator: " / ")
    }

    private func chordName(for degree: String, isSeventh: Bool) -> String {
        guard let root = effectiveRoot else { return degree }
        return chordDescriptor(for: degree, root: root, isSeventh: isSeventh)?.name ?? degree
    }

    private func slashConfiguration(for barIndex: Int) -> PopularSlashChordConfiguration {
        if let storedConfiguration = slashChordConfigurations[barIndex] {
            return storedConfiguration
        }

        let firstIndex = progression.flatIndex(barIndex: barIndex, chordIndex: 0)
        let secondIndex = progression.flatIndex(barIndex: barIndex, chordIndex: 1)

        if seventhChordIndexes.contains(firstIndex) {
            return .seventhSeventh
        }
        if seventhChordIndexes.contains(secondIndex) {
            return .triadSeventh
        }
        return .triadTriad
    }

    private func setSlashConfiguration(
        _ configuration: PopularSlashChordConfiguration,
        for barIndex: Int
    ) {
        let firstIndex = progression.flatIndex(barIndex: barIndex, chordIndex: 0)
        let secondIndex = progression.flatIndex(barIndex: barIndex, chordIndex: 1)
        var indexes = Set(seventhChordIndexes)
        indexes.remove(firstIndex)
        indexes.remove(secondIndex)

        if configuration.firstIsSeventh {
            indexes.insert(firstIndex)
        }
        if configuration.secondIsSeventh {
            indexes.insert(secondIndex)
        }
        seventhChordIndexes = indexes.sorted()
        slashChordConfigurations[barIndex] = configuration
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

    @ViewBuilder
    private var actionButton: some View {
        switch action {
        case .favorite(let isFavorite):
            Button {
                isFavorite.wrappedValue.toggle()
            } label: {
                Image(systemName: isFavorite.wrappedValue ? "star.fill" : "star")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(isFavorite.wrappedValue ? HarmonyColor.yellow.color : AppColors.primaryText)
                    .frame(width: 40, height: 38)
                    .background(AppColors.control, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isFavorite.wrappedValue ? "Удалить из избранного" : "Добавить в избранное")
        case .delete(let delete):
            Button(role: .destructive, action: delete) {
                Image(systemName: "trash")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(HarmonyColor.red.color)
                    .frame(width: 40, height: 38)
                    .background(AppColors.control, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Удалить последовательность")
        }
    }

    private var playbackChords: [PlaybackChord] {
        guard let root = effectiveRoot else { return [] }
        return progression.bars.enumerated().flatMap { barIndex, bar in
            let activeChordCount = activeChordCount(in: barIndex)
            return bar.enumerated().compactMap { chordIndex, degree -> PlaybackChord? in
                let flatIndex = progression.flatIndex(
                    barIndex: barIndex,
                    chordIndex: chordIndex
                )
                guard isActiveChord(barIndex: barIndex, chordIndex: chordIndex) else {
                    return nil
                }
                guard let chord = chordDescriptor(
                    for: degree,
                    root: root,
                    isSeventh: isSeventhChord(
                        barIndex: barIndex,
                        chordIndex: chordIndex,
                        flatIndex: flatIndex
                    )
                ) else { return nil }
                return PlaybackChord(
                    rootPitchClass: chord.rootPitchClass,
                    intervals: chord.intervals,
                    durationMultiplier: 1 / Double(max(activeChordCount, 1))
                )
            }
        }
    }

    private var playbackButton: some View {
        Button {
            audioPlayer.play(chords: playbackChords, bpm: tempoBPM)
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

    private func isSeventhChord(
        barIndex: Int,
        chordIndex: Int,
        flatIndex: Int
    ) -> Bool {
        guard progression.bars[barIndex].count == 2 else {
            return seventhChordIndexes.contains(flatIndex)
        }

        let configuration = slashConfiguration(for: barIndex)
        return chordIndex == 0
            ? configuration.firstIsSeventh
            : configuration.secondIsSeventh
    }

    private func isActiveChord(barIndex: Int, chordIndex: Int) -> Bool {
        guard progression.bars[barIndex].count == 2 else { return true }
        let configuration = slashConfiguration(for: barIndex)
        return chordIndex == 0
            ? configuration.firstIsActive
            : configuration.secondIsActive
    }

    private func activeChordCount(in barIndex: Int) -> Int {
        guard progression.bars[barIndex].count == 2 else {
            return progression.bars[barIndex].count
        }
        let configuration = slashConfiguration(for: barIndex)
        return [configuration.firstIsActive, configuration.secondIsActive]
            .filter { $0 }
            .count
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
