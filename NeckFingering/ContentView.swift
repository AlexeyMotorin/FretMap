import SwiftUI

struct ContentView: View {
    @StateObject private var store = AppSettingsStore()

    private let scales = ScalePattern.all
    private let tunings = TuningPreset.all

    private var noteNames: [String] { store.accidentalStyle.noteNames }
    private var selectedScale: ScalePattern { scales.first { $0.id == store.selectedScaleID } ?? .ionian }
    private var popularScale: ScalePattern { scales.first { $0.id == store.popularScaleID } ?? .ionian }
    private var compatibleTunings: [TuningPreset] { tunings.filter { $0.stringCount == store.stringCount } }
    private var selectedTuning: TuningPreset { compatibleTunings.first { $0.id == store.selectedTuningID } ?? compatibleTunings[0] }

    var body: some View {
        GeometryReader { proxy in
            if store.isCustomMode {
                customModeView
                    .frame(width: proxy.size.width, height: proxy.size.height)
            } else {
                ZStack(alignment: .bottom) {
                    content
                        .id(store.appMode)
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
                .animation(nil, value: store.appMode)
                .onAppear {
                    syncSavedSelections()
                }
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch store.appMode {
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
        if store.isModeSwitcherVisible {
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
                noAnimation { store.isModeSwitcherVisible = false }
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
            noAnimation { store.isModeSwitcherVisible = true }
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
                if store.isSettingsVisible {
                    settingsPanel
                        .frame(width: min(320, max(280, proxy.size.width * 0.27)))
                        .frame(height: proxy.size.height)
                }

                ZStack(alignment: .topLeading) {
                    FretboardView(
                        tuning: selectedTuning,
                        fretCount: store.fretCount,
                        markers: scaleMarkers,
                        barres: [],
                        selectedPositions: [],
                        customMode: false,
                        onTapPosition: nil,
                        onSwipe: store.isSettingsVisible ? { setSettingsVisible(false) } : nil
                    )

                    if !store.isSettingsVisible {
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
                chordSettingsPanel
                    .frame(width: min(320, max(280, proxy.size.width * 0.27)))
                    .frame(height: proxy.size.height)

                ZStack(alignment: .topLeading) {
                    FretboardView(
                        tuning: selectedTuning,
                        fretCount: store.fretCount,
                        visibleFretRange: chordVisibleFretRange,
                        markers: chordMarkers,
                        barres: chordBarres,
                        selectedPositions: [],
                        customMode: false,
                        onTapPosition: nil,
                        onSwipe: nil
                    )
                    .highPriorityGesture(chordShapeSwipeGesture)

                    chordTitleOverlay
                        .padding(12)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                        .allowsHitTesting(false)

                    chordShapeCounterOverlay
                        .padding(.trailing, 12)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
                        .allowsHitTesting(false)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(AppColors.page)
        .clipped()
    }

    private var harmonyModeView: some View {
        VStack(spacing: 0) {
            Picker("Гармония", selection: noAnimationBinding($store.harmonyMode)) {
                ForEach(HarmonyMode.allCases) { mode in
                    Text(mode.title).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .padding(12)
            .background(AppColors.panel)

            switch store.harmonyMode {
            case .functional:
                FunctionalHarmonyView(noteNames: noteNames, store: store)
            case .modal:
                ModalHarmonyView(noteNames: noteNames, store: store)
            case .popular:
                PopularHarmonyView(scale: popularScale, noteNames: noteNames, store: store)
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

                notePicker(title: "Тональность", selection: noAnimationBinding($store.rootNote))

                UIKitMenuPicker(title: "Лад", selection: noAnimationBinding($store.selectedScaleID), options: scales.map { MenuPickerItem(value: $0.id, title: $0.name) })
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
                        Text("Тоника, строй и тип аккорда")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(AppColors.mutedText)
                    }
                }

                notePicker(title: "Тоника аккорда", selection: noAnimationBinding($store.chordSettings.root))
                accidentalPicker
                chordStringCountPicker
                tuningPicker
                chordQualityPicker
                chordSizePicker
                degreeNumbersToggle

                Button {
                    store.customPositions.removeAll()
                    store.isCustomMode = true
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
                fretCount: store.fretCount,
                visibleFretRange: customVisibleFretRange,
                markers: [],
                barres: [],
                selectedPositions: store.customPositions,
                selectedPositionLabels: customPositionLabels,
                customMode: true,
                onTapPosition: toggleCustomPosition,
                onSwipe: nil
            )

            Button {
                store.isCustomMode = false
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
                    .allowsHitTesting(false)
            }
        }
        .background(AppColors.fretboard)
    }

    private var popularHarmonyBottomBar: some View {
        HStack {
            UIKitMenuPicker(title: "Лад", selection: noAnimationBinding($store.popularScaleID), options: ScalePattern.all.prefix(7).map { MenuPickerItem(value: $0.id, title: $0.shortName) })
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
        Picker("Ноты", selection: noAnimationBinding($store.accidentalStyle)) {
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

    private var chordStringCountPicker: some View {
        Picker("Струны", selection: chordStringCountBinding) {
            ForEach(6...8, id: \.self) { count in
                Text("\(count)").tag(count)
            }
        }
        .pickerStyle(.segmented)
    }

    private var tuningPicker: some View {
        UIKitMenuPicker(title: "Строй", selection: tuningSelectionBinding, options: compatibleTunings.map { MenuPickerItem(value: $0.id, title: $0.name) })
            .frame(maxWidth: .infinity, minHeight: 44, maxHeight: 44)
    }

    private var chordQualityPicker: some View {
        UIKitMenuPicker(title: "Вид", selection: chordQualityBinding, options: ChordQuality.allCases.map { MenuPickerItem(value: $0, title: $0.title) })
            .frame(maxWidth: .infinity, minHeight: 44, maxHeight: 44)
    }

    private var chordSizePicker: some View {
        Picker("Размер", selection: chordSizeBinding) {
            ForEach(availableChordSizes) { size in
                Text(size.title).tag(size)
            }
        }
        .pickerStyle(.segmented)
    }

    private var fretStepper: some View {
        Stepper("Лады: \(store.fretCount)", value: noAnimationBinding($store.fretCount), in: 12...24, step: 1)
            .foregroundStyle(AppColors.primaryText)
            .tint(AppColors.primaryText)
    }

    private var degreeNumbersToggle: some View {
        Toggle("Ступени", isOn: noAnimationBinding($store.showsDegreeNumbers))
            .toggleStyle(.switch)
            .font(.system(.subheadline, design: .rounded).weight(.semibold))
            .foregroundStyle(AppColors.primaryText)
            .tint(AppColors.rootText)
            .transaction { transaction in
                transaction.animation = nil
                transaction.disablesAnimations = true
            }
    }

    @ViewBuilder
    private var chordTitleOverlay: some View {
        if let shape = selectedChordShape {
            VStack(alignment: .trailing, spacing: 2) {
                Text(chordDisplayName)
                    .font(.system(.title3, design: .rounded).weight(.black))
                    .foregroundStyle(AppColors.primaryText)
                Text(shape.title)
                    .font(.system(.caption, design: .rounded).weight(.bold))
                    .foregroundStyle(AppColors.mutedText)
                    .lineLimit(1)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(AppColors.panel.opacity(0.94), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
    }

    @ViewBuilder
    private var chordShapeCounterOverlay: some View {
        let shapes = availableChordShapes
        if shapes.count > 1, let index = selectedChordShapeIndex {
            VStack(spacing: 8) {
                Image(systemName: "chevron.up")
                    .font(.system(size: 13, weight: .black))
                Text("\(index + 1) / \(shapes.count)")
                    .font(.system(.headline, design: .rounded).weight(.black))
                    .monospacedDigit()
                Image(systemName: "chevron.down")
                    .font(.system(size: 13, weight: .black))
            }
            .foregroundStyle(AppColors.primaryText)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(AppColors.panel.opacity(0.94), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
    }

    private var scaleSummary: String {
        selectedScale.intervals.map { noteNames[($0 + store.rootNote) % 12] }.joined(separator: "  ")
    }

    private var scaleMarkers: [FretMarker] {
        makeMarkers { stringIndex, fret, pitch in
            guard selectedScale.intervals.contains((pitch - store.rootNote + 12) % 12),
                  let degree = selectedScale.degreeLabel(for: pitch, root: store.rootNote) else { return nil }
            let label = store.showsDegreeNumbers ? "\(noteNames[pitch])/\(degree)" : noteNames[pitch]
            return FretMarker(position: FretPosition(stringIndex: stringIndex, fret: fret), label: label, isRoot: pitch == store.rootNote)
        }
    }

    private var chordMarkers: [FretMarker] {
        guard store.stringCount >= 6 else { return [] }

        if let cagedMarkers = cagedChordMarkers {
            return cagedMarkers
        }

        let intervals = store.chordSettings.intervals
        let tones = store.chordSettings.tones
        return makeMarkers { stringIndex, fret, pitch in
            let guitarStringNumber = stringIndex + 1
            guard guitarStringNumber <= store.chordSettings.startString else { return nil }
            let interval = (pitch - store.chordSettings.root + 12) % 12
            guard intervals.contains(interval) else { return nil }
            let degree = tones.first { $0.interval == interval }?.degree ?? ""
            let label = store.showsDegreeNumbers ? "\(noteNames[pitch])/\(degree)" : noteNames[pitch]
            return FretMarker(position: FretPosition(stringIndex: stringIndex, fret: fret), label: label, isRoot: interval == 0)
        }
    }

    private var chordBarres: [ChordBarre] {
        guard usesCagedChordShape, let shape = selectedChordShape else { return [] }
        return shape.transposedBarres(to: store.chordSettings.root)
    }

    private var chordVisibleFretRange: ClosedRange<Int>? {
        guard usesCagedChordShape else { return nil }
        let markerFrets = chordMarkers.map { $0.position.fret }
        let barreFrets = chordBarres.map(\.fret)
        let frets = markerFrets + barreFrets
        guard let minFret = frets.min(), let maxFret = frets.max() else { return nil }

        if minFret == 0 {
            return 0...min(store.fretCount, max(maxFret + 1, 4))
        }

        let start = max(1, minFret - 1)
        let end = min(store.fretCount, max(maxFret + 1, start + 3))
        return start...end
    }

    private var cagedChordMarkers: [FretMarker]? {
        guard usesCagedChordShape, let shape = selectedChordShape else { return nil }
        let displayedStrings = Array(selectedTuning.strings.reversed())
        return shape.transposedNotes(to: store.chordSettings.root).compactMap { note in
            let stringIndex = note.stringNumber - 1
            guard displayedStrings.indices.contains(stringIndex), (0...store.fretCount).contains(note.fret) else { return nil }
            let pitch = (displayedStrings[stringIndex].pitchClass + note.fret) % 12
            let interval = (pitch - store.chordSettings.root + 12) % 12
            let degree = store.chordSettings.tones.first { $0.interval == interval }?.degree ?? (interval == 9 ? "bb7" : "")
            let label = store.showsDegreeNumbers && !degree.isEmpty ? "\(noteNames[pitch])/\(degree)" : noteNames[pitch]
            return FretMarker(position: FretPosition(stringIndex: stringIndex, fret: note.fret), label: label, isRoot: interval == 0)
        }
    }

    private var usesCagedChordShape: Bool {
        supportsCagedChordShapes && selectedChordShape != nil
    }

    private var availableChordShapes: [ChordShape] {
        ChordFingeringDatabase.shapes(
            quality: store.chordSettings.quality,
            size: store.chordSettings.size,
            maxRootString: store.stringCount
        )
    }

    private var supportsCagedChordShapes: Bool {
        let standardTopSix = [4, 9, 2, 7, 11, 4]
        return selectedTuning.strings.suffix(6).map(\.pitchClass) == standardTopSix
    }

    private var availableChordSizes: [ChordSize] {
        ChordSize.available(for: store.chordSettings.quality)
    }

    private var selectedChordShape: ChordShape? {
        let shapes = availableChordShapes
        return shapes.first { $0.id == store.chordSettings.shapeID } ?? shapes.first
    }

    private var selectedChordShapeIndex: Int? {
        guard let selectedChordShape else { return nil }
        return availableChordShapes.firstIndex(of: selectedChordShape)
    }

    private var chordDisplayName: String {
        "\(noteNames[store.chordSettings.root])\(store.chordSettings.displaySuffix)"
    }

    private var chordShapeSwipeGesture: some Gesture {
        DragGesture(minimumDistance: 18)
            .onEnded { value in
                let vertical = value.translation.height
                guard abs(vertical) > abs(value.translation.width), abs(vertical) > 24 else { return }
                selectChordShape(offset: vertical < 0 ? 1 : -1)
            }
    }

    private func syncChordShape() {
        if !availableChordSizes.contains(store.chordSettings.size) {
            store.chordSettings.size = availableChordSizes.first ?? .triad
        }
        guard let firstShape = availableChordShapes.first else { return }
        if !availableChordShapes.contains(where: { $0.id == store.chordSettings.shapeID }) {
            store.chordSettings.shapeID = firstShape.id
        }
    }

    private func selectChordShape(offset: Int) {
        let shapes = availableChordShapes
        guard shapes.count > 1 else { return }
        let currentIndex = selectedChordShapeIndex ?? 0
        let nextIndex = (currentIndex + offset + shapes.count) % shapes.count
        noAnimation { store.chordSettings.shapeID = shapes[nextIndex].id }
    }

    private var customVisibleFretRange: ClosedRange<Int> {
        0...min(store.fretCount, 12)
    }

    private var customPositionLabels: [FretPosition: String] {
        let displayedStrings = Array(selectedTuning.strings.reversed())
        return Dictionary(uniqueKeysWithValues: store.customPositions.compactMap { position in
            guard displayedStrings.indices.contains(position.stringIndex) else { return nil }
            let pitch = (displayedStrings[position.stringIndex].pitchClass + position.fret) % 12
            return (position, noteNames[pitch])
        })
    }

    private func makeMarkers(_ builder: (Int, Int, Int) -> FretMarker?) -> [FretMarker] {
        let displayedStrings = Array(selectedTuning.strings.reversed())
        var markers: [FretMarker] = []
        for stringIndex in displayedStrings.indices {
            let string = displayedStrings[stringIndex]
            for fret in 0...store.fretCount {
                let pitch = (string.pitchClass + fret) % 12
                if let marker = builder(stringIndex, fret, pitch) {
                    markers.append(marker)
                }
            }
        }
        return markers
    }

    private func toggleCustomPosition(_ position: FretPosition) {
        noAnimation {
            if store.customPositions.contains(position) {
                store.customPositions.remove(position)
            } else {
                store.customPositions = Set(store.customPositions.filter { $0.stringIndex != position.stringIndex })
                store.customPositions.insert(position)
            }
        }
    }

    private var identifiedCustomChord: String? {
        let displayedStrings = Array(selectedTuning.strings.reversed())
        let pitches = Set(store.customPositions.compactMap { position -> Int? in
            guard displayedStrings.indices.contains(position.stringIndex) else { return nil }
            return (displayedStrings[position.stringIndex].pitchClass + position.fret) % 12
        })
        return ChordIdentifier.identify(pitchClasses: pitches, noteNames: noteNames)
    }

    private var stringCountBinding: Binding<Int> {
        Binding(
            get: { store.stringCount },
            set: { newValue in
                noAnimation { setStringCount(newValue) }
            }
        )
    }

    private var chordStringCountBinding: Binding<Int> {
        Binding(
            get: { max(store.stringCount, 6) },
            set: { newValue in
                noAnimation { setStringCount(max(newValue, 6)) }
            }
        )
    }

    private var chordQualityBinding: Binding<ChordQuality> {
        Binding(
            get: { store.chordSettings.quality },
            set: { newValue in
                noAnimation {
                    store.chordSettings.quality = newValue
                    syncChordShape()
                }
            }
        )
    }

    private var chordSizeBinding: Binding<ChordSize> {
        Binding(
            get: { store.chordSettings.size },
            set: { newValue in
                noAnimation {
                    store.chordSettings.size = newValue
                    syncChordShape()
                }
            }
        )
    }

    private var modeSelectionBinding: Binding<AppMode> {
        Binding(
            get: { store.appMode },
            set: { newValue in
                noAnimation {
                    store.appMode = newValue
                    if newValue == .chords {
                        ensureChordStringCount()
                    }
                }
            }
        )
    }

    private var tuningSelectionBinding: Binding<String> {
        Binding(
            get: { selectedTuning.id },
            set: { newValue in
                noAnimation {
                    store.selectedTuningID = newValue
                    syncChordShape()
                }
            }
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
        noAnimation { store.isSettingsVisible = visible }
    }

    private func syncSavedSelections() {
        store.normalize()
        if store.appMode == .chords {
            ensureChordStringCount()
        }
        syncChordShape()
    }

    private func ensureChordStringCount() {
        if store.stringCount < 6 {
            setStringCount(6)
        }
    }

    private func setStringCount(_ count: Int) {
        store.stringCount = count
        store.chordSettings.startString = min(store.chordSettings.startString, count)
        let tuningsForCount = tunings.filter { $0.stringCount == count }
        guard let firstTuning = tuningsForCount.first else { return }
        if !tuningsForCount.contains(where: { $0.id == store.selectedTuningID }) {
            store.selectedTuningID = firstTuning.id
        }
        syncChordShape()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
