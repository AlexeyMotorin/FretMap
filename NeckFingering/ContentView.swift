import SwiftUI

struct ContentView: View {
    @State private var appMode: AppMode = .modes
    @State private var rootNote = 0
    @State private var selectedScaleID = ScalePattern.ionian.id
    @State private var stringCount = 6
    @State private var selectedTuningID = TuningPreset.standard6.id
    @State private var fretCount = 24
    @State private var accidentalStyle = AccidentalStyle.flats
    @State private var isSettingsVisible = true
    @State private var chordSettings = ChordSettings()
    @State private var isCustomMode = false
    @State private var customPositions: Set<FretPosition> = []
    @State private var harmonyMode: HarmonyMode = .functional
    @State private var popularScaleID = ScalePattern.ionian.id
    @State private var isModeSwitcherVisible = true
    @State private var showsDegreeNumbers = true

    private let scales = ScalePattern.all
    private let tunings = TuningPreset.all

    private var noteNames: [String] { accidentalStyle.noteNames }
    private var selectedScale: ScalePattern { scales.first { $0.id == selectedScaleID } ?? .ionian }
    private var popularScale: ScalePattern { scales.first { $0.id == popularScaleID } ?? .ionian }
    private var compatibleTunings: [TuningPreset] { tunings.filter { $0.stringCount == stringCount } }
    private var selectedTuning: TuningPreset { compatibleTunings.first { $0.id == selectedTuningID } ?? compatibleTunings[0] }

    var body: some View {
        GeometryReader { proxy in
            if isCustomMode {
                customModeView
                    .frame(width: proxy.size.width, height: proxy.size.height)
            } else {
                ZStack(alignment: .bottom) {
                    content
                        .id(appMode)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .clipped()
                        .transition(.identity)

                    modeSwitcherOverlay
                        .zIndex(20)
                }
                .frame(width: proxy.size.width, height: proxy.size.height)
                .background(AppColors.page.ignoresSafeArea())
                .transaction { transaction in
                    transaction.animation = nil
                    transaction.disablesAnimations = true
                }
                .animation(nil, value: appMode)
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch appMode {
        case .chords:
            chordsModeView
        case .modes:
            modesModeView
        case .harmony:
            harmonyModeView
        }
    }

    @ViewBuilder
    private var modeSwitcherOverlay: some View {
        if isModeSwitcherVisible {
            topModePicker
                .padding(.bottom, 8)
                .padding(.horizontal, 12)
        } else {
            showModeSwitcherButton
                .padding(.bottom, 8)
                .padding(.trailing, 14)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }

    private var topModePicker: some View {
        HStack(spacing: 8) {
            Picker("Режим", selection: modeSelectionBinding) {
                ForEach(AppMode.allCases) { mode in
                    Text(mode.title).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .frame(maxWidth: 420)

            Button {
                noAnimation { isModeSwitcherVisible = false }
            } label: {
                Image(systemName: "chevron.down")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(AppColors.primaryText)
                    .frame(width: 38, height: 38)
                    .background(AppColors.control, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(6)
        .background(AppColors.panel.opacity(0.96), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .shadow(color: .black.opacity(0.24), radius: 12, x: 0, y: 4)
        .transaction { transaction in
            transaction.animation = nil
            transaction.disablesAnimations = true
        }
    }

    private var showModeSwitcherButton: some View {
        Button {
            noAnimation { isModeSwitcherVisible = true }
        } label: {
            Image(systemName: "chevron.up")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(AppColors.primaryText)
                .frame(width: 52, height: 34)
                .background(AppColors.panel.opacity(0.96), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                .shadow(color: .black.opacity(0.22), radius: 10, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }

    private var modesModeView: some View {
        GeometryReader { proxy in
            HStack(alignment: .top, spacing: 0) {
                if isSettingsVisible {
                    settingsPanel
                        .frame(width: min(320, max(280, proxy.size.width * 0.27)))
                        .frame(height: proxy.size.height)
                }

                ZStack(alignment: .topLeading) {
                    FretboardView(
                        tuning: selectedTuning,
                        fretCount: fretCount,
                        markers: scaleMarkers,
                        selectedPositions: [],
                        customMode: false,
                        onTapPosition: nil,
                        onSwipe: isSettingsVisible ? { setSettingsVisible(false) } : nil
                    )

                    if !isSettingsVisible {
                        settingsButton
                            .padding(12)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .clipped()
    }

    private var chordsModeView: some View {
        GeometryReader { proxy in
            HStack(alignment: .top, spacing: 0) {
                if isSettingsVisible {
                    chordSettingsPanel
                        .frame(width: min(320, max(280, proxy.size.width * 0.27)))
                        .frame(height: proxy.size.height)
                }

                ZStack(alignment: .topLeading) {
                    FretboardView(
                        tuning: selectedTuning,
                        fretCount: fretCount,
                        markers: chordMarkers,
                        selectedPositions: [],
                        customMode: false,
                        onTapPosition: nil,
                        onSwipe: isSettingsVisible ? { setSettingsVisible(false) } : nil
                    )

                    if !isSettingsVisible {
                        settingsButton
                            .padding(12)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(AppColors.page)
        .clipped()
    }

    private var harmonyModeView: some View {
        VStack(spacing: 0) {
            Picker("Гармония", selection: noAnimationBinding($harmonyMode)) {
                ForEach(HarmonyMode.allCases) { mode in
                    Text(mode.title).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .padding(12)
            .background(AppColors.panel)

            switch harmonyMode {
            case .functional:
                FunctionalHarmonyView()
            case .modal:
                ModalHarmonyView()
            case .popular:
                PopularHarmonyView(scale: popularScale)
                popularHarmonyBottomBar
            }
        }
    }

    private var settingsPanel: some View {
        ScrollView(.vertical) {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Лады")
                            .font(.title3.weight(.bold))
                            .foregroundStyle(AppColors.primaryText)
                        Text("Тональность, строй и ступени")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(AppColors.mutedText)
                    }
                    Spacer()
                    Button { setSettingsVisible(false) } label: {
                        Image(systemName: "gearshape.fill")
                            .foregroundStyle(AppColors.primaryText)
                            .frame(width: 36, height: 36)
                            .background(AppColors.control, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }

                notePicker(title: "Тональность", selection: noAnimationBinding($rootNote))

                UIKitMenuPicker(title: "Лад", selection: noAnimationBinding($selectedScaleID), options: scales.map { MenuPickerItem(value: $0.id, title: $0.name) })
                    .frame(maxWidth: .infinity, minHeight: 44, maxHeight: 44)

                accidentalPicker
                stringCountPicker
                tuningPicker
                fretStepper
                degreeNumbersToggle

                Divider().overlay(AppColors.mutedText.opacity(0.35))

                Text(scaleSummary)
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .foregroundStyle(AppColors.mutedText)
                    .lineLimit(3)
            }
            .padding(18)
            .padding(.bottom, 90)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .scrollIndicators(.hidden)
        .frame(maxHeight: .infinity, alignment: .topLeading)
        .background(AppColors.panel)
    }

    private var chordSettingsPanel: some View {
        ScrollView(.vertical) {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Аккорды")
                            .font(.title3.weight(.bold))
                            .foregroundStyle(AppColors.primaryText)
                        Text("Тоника, строй и аппликатура")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(AppColors.mutedText)
                    }
                    Spacer()
                    Button { setSettingsVisible(false) } label: {
                        Image(systemName: "gearshape.fill")
                            .foregroundStyle(AppColors.primaryText)
                            .frame(width: 36, height: 36)
                            .background(AppColors.control, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }

                notePicker(title: "Тоника аккорда", selection: noAnimationBinding($chordSettings.root))
                accidentalPicker
                stringCountPicker
                tuningPicker
                chordStartStringPicker
                chordQualityPicker
                chordSizePicker
                degreeNumbersToggle

                Button {
                    customPositions.removeAll()
                    isCustomMode = true
                } label: {
                    Label("Кастомный режим", systemImage: "hand.tap.fill")
                        .font(.system(.subheadline, design: .rounded).weight(.bold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(18)
            .padding(.bottom, 90)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .scrollIndicators(.hidden)
        .frame(maxHeight: .infinity, alignment: .topLeading)
        .background(AppColors.panel)
    }

    private var customModeView: some View {
        ZStack(alignment: .topLeading) {
            FretboardView(
                tuning: selectedTuning,
                fretCount: fretCount,
                markers: [],
                selectedPositions: customPositions,
                customMode: true,
                onTapPosition: toggleCustomPosition,
                onSwipe: nil
            )

            Button {
                isCustomMode = false
            } label: {
                Label("Назад", systemImage: "chevron.left")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(AppColors.primaryText)
                    .padding(.horizontal, 14)
                    .frame(height: 44)
                    .background(AppColors.panel.opacity(0.95), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            .buttonStyle(.plain)
            .padding(12)

            if let name = identifiedCustomChord {
                Text(name)
                    .font(.title3.weight(.black))
                    .foregroundStyle(AppColors.primaryText)
                    .padding(.horizontal, 16)
                    .frame(height: 44)
                    .background(AppColors.panel.opacity(0.95), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(12)
            }
        }
        .background(AppColors.fretboard)
    }

    private var popularHarmonyBottomBar: some View {
        HStack {
            UIKitMenuPicker(title: "Лад", selection: noAnimationBinding($popularScaleID), options: ScalePattern.all.prefix(7).map { MenuPickerItem(value: $0.id, title: $0.shortName) })
                .frame(width: 320, height: 44)
            Spacer()
        }
        .padding(12)
        .background(AppColors.panel)
    }

    private var settingsButton: some View {
        Button { setSettingsVisible(true) } label: {
            Image(systemName: "gearshape.fill")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(AppColors.primaryText)
                .frame(width: 44, height: 44)
                .background(AppColors.panel.opacity(0.96), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func notePicker(title: String, selection: Binding<Int>) -> some View {
        UIKitMenuPicker(
            title: title,
            selection: selection,
            options: noteNames.indices.map { MenuPickerItem(value: $0, title: noteNames[$0]) }
        )
        .frame(maxWidth: .infinity, minHeight: 44, maxHeight: 44)
    }

    private var accidentalPicker: some View {
        Picker("Ноты", selection: noAnimationBinding($accidentalStyle)) {
            ForEach(AccidentalStyle.allCases) { style in
                Text(style.title).tag(style)
            }
        }
        .pickerStyle(.segmented)
    }

    private var stringCountPicker: some View {
        Picker("Струны", selection: stringCountBinding) {
            ForEach(4...8, id: \.self) { count in
                Text("\(count)").tag(count)
            }
        }
        .pickerStyle(.segmented)
    }

    private var tuningPicker: some View {
        UIKitMenuPicker(title: "Строй", selection: tuningSelectionBinding, options: compatibleTunings.map { MenuPickerItem(value: $0.id, title: $0.name) })
            .frame(maxWidth: .infinity, minHeight: 44, maxHeight: 44)
    }

    private var chordStartStringPicker: some View {
        UIKitMenuPicker(title: "Струна", selection: noAnimationBinding($chordSettings.startString), options: (1...stringCount).reversed().map { MenuPickerItem(value: $0, title: "\($0)") })
            .frame(maxWidth: .infinity, minHeight: 44, maxHeight: 44)
    }

    private var chordQualityPicker: some View {
        UIKitMenuPicker(title: "Вид", selection: noAnimationBinding($chordSettings.quality), options: ChordQuality.allCases.map { MenuPickerItem(value: $0, title: $0.title) })
            .frame(maxWidth: .infinity, minHeight: 44, maxHeight: 44)
    }

    private var chordSizePicker: some View {
        Picker("Размер", selection: noAnimationBinding($chordSettings.size)) {
            ForEach(ChordSize.allCases) { size in
                Text(size.title).tag(size)
            }
        }
        .pickerStyle(.segmented)
    }

    private var fretStepper: some View {
        Stepper("Лады: \(fretCount)", value: noAnimationBinding($fretCount), in: 12...24, step: 1)
            .foregroundStyle(AppColors.primaryText)
            .tint(AppColors.primaryText)
    }

    private var degreeNumbersToggle: some View {
        Toggle("Ступени", isOn: noAnimationBinding($showsDegreeNumbers))
            .toggleStyle(.switch)
            .font(.system(.subheadline, design: .rounded).weight(.semibold))
            .foregroundStyle(AppColors.primaryText)
            .tint(AppColors.rootText)
            .transaction { transaction in
                transaction.animation = nil
                transaction.disablesAnimations = true
            }
    }

    private var scaleSummary: String {
        selectedScale.intervals.map { noteNames[($0 + rootNote) % 12] }.joined(separator: "  ")
    }

    private var scaleMarkers: [FretMarker] {
        makeMarkers { stringIndex, fret, pitch in
            guard selectedScale.intervals.contains((pitch - rootNote + 12) % 12),
                  let degree = selectedScale.degreeLabel(for: pitch, root: rootNote) else { return nil }
            let label = showsDegreeNumbers ? "\(noteNames[pitch])/\(degree)" : noteNames[pitch]
            return FretMarker(position: FretPosition(stringIndex: stringIndex, fret: fret), label: label, isRoot: pitch == rootNote)
        }
    }

    private var chordMarkers: [FretMarker] {
        let intervals = chordSettings.intervals
        let tones = chordSettings.tones
        return makeMarkers { stringIndex, fret, pitch in
            let guitarStringNumber = stringIndex + 1
            guard guitarStringNumber <= chordSettings.startString else { return nil }
            let interval = (pitch - chordSettings.root + 12) % 12
            guard intervals.contains(interval) else { return nil }
            let degree = tones.first { $0.interval == interval }?.degree ?? ""
            let label = showsDegreeNumbers ? "\(noteNames[pitch])/\(degree)" : noteNames[pitch]
            return FretMarker(position: FretPosition(stringIndex: stringIndex, fret: fret), label: label, isRoot: interval == 0)
        }
    }

    private func makeMarkers(_ builder: (Int, Int, Int) -> FretMarker?) -> [FretMarker] {
        let displayedStrings = Array(selectedTuning.strings.reversed())
        var markers: [FretMarker] = []
        for stringIndex in displayedStrings.indices {
            let string = displayedStrings[stringIndex]
            for fret in 0...fretCount {
                let pitch = (string.pitchClass + fret) % 12
                if let marker = builder(stringIndex, fret, pitch) {
                    markers.append(marker)
                }
            }
        }
        return markers
    }

    private func toggleCustomPosition(_ position: FretPosition) {
        if customPositions.contains(position) {
            customPositions.remove(position)
        } else {
            customPositions.insert(position)
        }
    }

    private var identifiedCustomChord: String? {
        let displayedStrings = Array(selectedTuning.strings.reversed())
        let pitches = Set(customPositions.compactMap { position -> Int? in
            guard displayedStrings.indices.contains(position.stringIndex) else { return nil }
            return (displayedStrings[position.stringIndex].pitchClass + position.fret) % 12
        })
        return ChordIdentifier.identify(pitchClasses: pitches, noteNames: noteNames)
    }

    private var stringCountBinding: Binding<Int> {
        Binding(
            get: { stringCount },
            set: { newValue in
                noAnimation {
                    stringCount = newValue
                    chordSettings.startString = min(chordSettings.startString, newValue)
                    let tuningsForCount = tunings.filter { $0.stringCount == newValue }
                    guard let firstTuning = tuningsForCount.first else { return }
                    if !tuningsForCount.contains(where: { $0.id == selectedTuningID }) {
                        selectedTuningID = firstTuning.id
                    }
                }
            }
        )
    }

    private var modeSelectionBinding: Binding<AppMode> {
        Binding(
            get: { appMode },
            set: { newValue in noAnimation { appMode = newValue } }
        )
    }

    private var tuningSelectionBinding: Binding<String> {
        Binding(
            get: { selectedTuning.id },
            set: { newValue in noAnimation { selectedTuningID = newValue } }
        )
    }

    private func noAnimationBinding<Value>(_ binding: Binding<Value>) -> Binding<Value> {
        Binding(get: { binding.wrappedValue }, set: { value in noAnimation { binding.wrappedValue = value } })
    }

    private func noAnimation(_ updates: () -> Void) {
        var transaction = Transaction()
        transaction.animation = nil
        transaction.disablesAnimations = true
        withTransaction(transaction) { updates() }
    }

    private func setSettingsVisible(_ visible: Bool) {
        noAnimation { isSettingsVisible = visible }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
