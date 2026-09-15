import SwiftUI
import UIKit

struct HomeCoordinatorView: View {
    @ObservedObject var store: AppSettingsStore
    @Binding var customTuningTargetMode: AppMode?
    @Binding var isCreatingSavedProgression: Bool
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @State private var isModeSelectionVisible = true
    @State private var showsBackup = false

    private let scales = ScalePattern.all
    private let tuningCatalog = TuningCatalog()
    private let manageCustomTuningID = "__manage_custom_tuning__"
    // Temporarily disabled while the custom chord workflow is being revised.
    private let isCustomModeAvailable = false
    // Temporarily disabled while scale box behavior is being revised.
    private let areScaleBoxesAvailable = false

    private var noteNames: [String] { noteNames(for: store.appMode == .chords || store.isCustomMode ? .chords : .modes) }
    private var showsDegreeNumbers: Bool { store.appMode == .chords || store.isCustomMode ? store.chordShowsDegreeNumbers : store.showsDegreeNumbers }
    private var selectedScale: ScalePattern { scales.first { $0.id == store.selectedScaleID } ?? .ionian }
    private var activeFretCount: Int { store.appMode == .chords || store.isCustomMode ? store.chordFretCount : store.fretCount }
    private var selectedTuning: TuningPreset {
        selectedTuning(for: store.appMode == .chords || store.isCustomMode ? .chords : .modes)
    }
    private var isPortraitLayout: Bool { verticalSizeClass != .compact }

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .topLeading) {
                AppBackgroundView()
                    .allowsHitTesting(false)

                if isModeSelectionVisible {
                    HomeModeSelectionView(
                        isPortrait: isPortraitLayout,
                        containerSize: proxy.size,
                        onSelectMode: openMode,
                        onBackup: { showsBackup = true }
                    )
                    .transition(.identity)
                } else if isCustomModeAvailable && store.isCustomMode {
                    CustomChordEditorView(
                        store: store,
                        tuning: selectedTuning,
                        fretCount: store.chordFretCount,
                        noteNames: noteNames,
                        onDismiss: {
                            noAnimation {
                                store.isCustomMode = false
                            }
                        }
                    )
                    .frame(width: proxy.size.width, height: proxy.size.height)
                } else {
                    ZStack(alignment: .topLeading) {
                        content
                            .frame(width: proxy.size.width, height: proxy.size.height, alignment: .topLeading)
                            .clipped()
                            .transition(.identity)

                        if store.appMode != .mastery && store.appMode != .harmony {
                            ModeBackButton(action: returnToModeSelection)
                                .padding(12)
                                .zIndex(10)
                        }
                    }
                    .id(store.appMode == .mastery ? "mastery" : "\(store.appMode.rawValue)-\(isPortraitLayout ? "portrait" : "landscape")")
                    .frame(width: proxy.size.width, height: proxy.size.height, alignment: .topLeading)
                    .clipped()
                }

                if let customTuningTargetMode {
                    CustomTuningEditorView(
                        presets: customTunings(for: customTuningTargetMode),
                        stringCount: stringCount(for: customTuningTargetMode),
                        noteNames: noteNames(for: customTuningTargetMode),
                        defaultPitchClasses: defaultTuningPitchClasses(
                            for: stringCount(for: customTuningTargetMode)
                        ),
                        onSave: saveCustomTuning,
                        onDelete: deleteCustomTuning,
                        onDismiss: {
                            noAnimation {
                                self.customTuningTargetMode = nil
                            }
                        }
                    )
                    .zIndex(40)
                    .transition(.identity)
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height, alignment: .topLeading)
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .ignoresSafeArea(.container, edges: .bottom)
        .transaction { transaction in
            transaction.animation = nil
            transaction.disablesAnimations = true
        }
        .animation(nil, value: store.appMode)
        .onAppear {
            syncSavedSelections()
            AppOrientationController.setSupportedOrientations(.allButUpsideDown)
        }
        .onChange(of: customTuningTargetMode) { targetMode in
            AppOrientationController.setSupportedOrientations(
                targetMode == nil ? supportedOrientations(for: store.appMode) : .portrait
            )
        }
        .sheet(isPresented: $showsBackup) { BackupView(settings: store) }
        .preferredColorScheme(.dark)
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
        case .mastery:
            MasteryPathView(onBack: returnToModeSelection)
        }
    }

    private var modesModeView: some View {
        GeometryReader { proxy in
            if isPortraitLayout {
                VStack(spacing: 12) {
                    // Leave room for navigation above the open-string labels.
                    modesFretboard
                        .frame(height: max(220, min(320, proxy.size.height * 0.42)))
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    settingsPanel
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .padding(.horizontal, 12)
                .padding(.top, 56)
                .padding(.bottom, max(12, proxy.safeAreaInsets.bottom))
            } else {
                HStack(alignment: .top, spacing: 0) {
                    if store.isSettingsVisible {
                        settingsPanel
                            .frame(width: min(320, max(280, proxy.size.width * 0.27)))
                    }
                    ZStack(alignment: .bottomLeading) {
                        modesFretboard
                        if !store.isSettingsVisible {
                            settingsButton.padding(12)
                        }
                    }
                }
            }
        }
        .clipped()
    }

    private var modesFretboard: some View {
        FretboardView(
            tuning: selectedTuning,
            fretCount: store.fretCount,
            allowsZoom: true,
            markers: scaleMarkers,
            barres: [],
            selectedPositions: [],
            customMode: false,
            onTapPosition: nil,
            onSwipe: !isPortraitLayout && store.isSettingsVisible ? { setSettingsVisible(false) } : nil
        )
    }

    private var chordsModeView: some View {
        GeometryReader { proxy in
            let isPortrait = isPortraitLayout

            Group {
                if isPortrait {
                    let fretboardHeight = portraitChordFretboardHeight(for: proxy.size.height)
                    let settingsHeight = max(220, proxy.size.height - fretboardHeight - 12)

                    VStack(spacing: 12) {
                        chordFretboard
                            .frame(
                                maxWidth: .infinity,
                                minHeight: fretboardHeight,
                                maxHeight: fretboardHeight
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                        portraitChordSettingsPanel
                            .frame(
                                maxWidth: .infinity,
                                minHeight: 0,
                                maxHeight: settingsHeight
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .frame(width: proxy.size.width, height: proxy.size.height, alignment: .topLeading)
                } else {
                    HStack(alignment: .top, spacing: 0) {
                        chordSettingsPanel
                            .frame(width: min(320, max(280, proxy.size.width * 0.27)))
                            .frame(height: proxy.size.height)

                        chordFretboard
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
            }
        }
        .background(Color.clear)
        .clipped()
    }

    private var harmonyModeView: some View {
        HarmonyRootView(
            store: store,
            noteNames: noteNames,
            isPortrait: isPortraitLayout,
            onBack: returnToModeSelection,
            onCreateSavedProgression: {
                isCreatingSavedProgression = true
            }
        )
    }

    private var chordFretboard: some View {
        ZStack(alignment: .topLeading) {
            FretboardView(
                tuning: selectedTuning,
                fretCount: store.chordFretCount,
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
        }
    }

    private var portraitChordSettingsPanel: some View {
        ScrollView(.vertical) {
            VStack(alignment: .leading, spacing: 10) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Аккорды")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(AppColors.primaryText)
                    Text("Тоника, строй и тип аккорда")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(AppColors.mutedText)
                }

                notePicker(title: "Тоника", selection: noAnimationBinding($store.chordSettings.root))

                accidentalPicker(for: .chords)

                tuningPicker(for: .chords)

                chordQualityPicker

                VStack(alignment: .leading, spacing: 4) {
                    Text("Струны")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(AppColors.mutedText)
                    chordStringCountPicker
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Состав")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(AppColors.mutedText)
                    chordSizePicker
                }

                compactChordExtensionsPicker

                VStack(spacing: 6) {
                    compactSettingsToggle(
                        "Ступени",
                        isOn: degreeNumbersBinding(for: .chords)
                    )
                    compactSettingsToggle(
                        "Выделить ступени цветом",
                        isOn: degreeColorsBinding(for: .chords)
                    )
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .scrollIndicators(.hidden)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .appSurface(fill: AppColors.panel)
    }

    private func portraitChordFretboardHeight(for availableHeight: CGFloat) -> CGFloat {
        min(320, max(220, availableHeight * 0.34))
    }

    private func compactSettingsToggle(_ title: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: 12) {
            Text(title)
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .foregroundStyle(AppColors.primaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            Spacer(minLength: 8)

            Toggle("", isOn: isOn)
                .labelsHidden()
                .toggleStyle(.switch)
                .tint(AppColors.rootText)
        }
        .frame(maxWidth: .infinity, minHeight: 36)
    }

    private var settingsPanel: some View {
        ScrollViewReader { scrollProxy in
            ScrollView(.vertical) {
                VStack(alignment: .leading, spacing: 14) {
                    Color.clear
                        .frame(height: 0)
                        .id("modes-settings-top")

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
                    if !isPortraitLayout {
                    Button { setSettingsVisible(false) } label: {
                        Image(systemName: "gearshape.fill")
                            .foregroundStyle(AppColors.primaryText)
                            .frame(width: 36, height: 36)
                            .appSurface(fill: AppColors.control)
                    }
                    .buttonStyle(.plain)
                    }
                }
                .padding(.leading, isPortraitLayout ? 0 : 48)

                notePicker(title: "Тональность", selection: noAnimationBinding($store.rootNote))

                UIKitMenuPicker(
                    title: "Лад",
                    selection: noAnimationBinding($store.selectedScaleID),
                    options: ScalePattern.primary.map { MenuPickerItem(value: $0.id, title: $0.name) },
                    additionalSections: [
                        MenuPickerSection(
                            title: "Ещё…",
                            items: ScalePattern.additional.map { MenuPickerItem(value: $0.id, title: $0.name) }
                        )
                    ]
                )
                    .frame(maxWidth: .infinity, minHeight: 44, maxHeight: 44)

                accidentalPicker(for: .modes)
                stringCountPicker
                tuningPicker(for: .modes)
                fretStepper
                degreeNumbersToggle(for: .modes)
                degreeColorsToggle(for: .modes)
                if areScaleBoxesAvailable {
                    scaleBoxesToggle
                }

                Divider().overlay(AppColors.mutedText.opacity(0.35))

                Text(scaleSummary)
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .foregroundStyle(AppColors.mutedText)
                    .lineLimit(3)
                }
                .padding(18)
                .padding(.bottom, 18)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .scrollIndicators(.hidden)
            .onAppear {
                scrollProxy.scrollTo("modes-settings-top", anchor: .top)
            }
        }
        .frame(maxHeight: .infinity, alignment: .topLeading)
        .background(AppColors.panel)
        .overlay(alignment: .trailing) {
            Rectangle()
                .fill(AppColors.border)
                .frame(width: 1)
        }
    }

    private var chordSettingsPanel: some View {
        ScrollViewReader { scrollProxy in
            ScrollView(.vertical) {
                VStack(alignment: .leading, spacing: 14) {
                    Color.clear
                        .frame(height: 0)
                        .id("chord-settings-top")

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
                .padding(.leading, 48)

                notePicker(title: "Тоника аккорда", selection: noAnimationBinding($store.chordSettings.root))
                accidentalPicker(for: .chords)
                chordStringCountPicker
                tuningPicker(for: .chords)
                chordQualityPicker
                chordSizePicker
                chordExtensionsPicker
                degreeNumbersToggle(for: .chords)
                degreeColorsToggle(for: .chords)

                if isCustomModeAvailable {
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
                }
                .padding(18)
                .padding(.bottom, 18)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .scrollIndicators(.hidden)
            .onAppear {
                scrollProxy.scrollTo("chord-settings-top", anchor: .top)
            }
        }
        .frame(maxHeight: .infinity, alignment: .topLeading)
        .background(AppColors.panel)
        .overlay(alignment: .trailing) {
            Rectangle()
                .fill(AppColors.border)
                .frame(width: 1)
        }
    }

    private var settingsButton: some View {
        Button { setSettingsVisible(true) } label: {
            Image(systemName: "gearshape.fill")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(AppColors.primaryText)
                .frame(width: 44, height: 44)
                .appSurface(fill: AppColors.elevatedPanel, castsShadow: true)
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

    private func accidentalPicker(for mode: AppMode) -> some View {
        Picker("Ноты", selection: accidentalStyleBinding(for: mode)) {
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

    private func tuningPicker(for mode: AppMode) -> some View {
        UIKitMenuPicker(title: "Строй", selection: tuningSelectionBinding(for: mode), options: tuningMenuOptions(for: mode))
            .frame(maxWidth: .infinity, minHeight: 44, maxHeight: 44)
    }

    private func tuningMenuOptions(for mode: AppMode) -> [MenuPickerItem<String>] {
        let builtIn = compatibleTunings(for: mode).map { MenuPickerItem(value: $0.id, title: $0.name) }
        let custom = customTunings(for: mode).map { preset in
            MenuPickerItem(value: tuningCatalog.menuID(forCustomTuningID: preset.id), title: preset.name)
        }
        return builtIn + custom + [MenuPickerItem(value: manageCustomTuningID, title: "Создать строй")]
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

    private var chordExtensionsPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 4) {
                Toggle("Надстройки", isOn: noAnimationBinding($store.areChordExtensionsVisible))
                    .toggleStyle(.switch)
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .foregroundStyle(AppColors.primaryText)
                    .tint(AppColors.rootText)
                    .transaction { transaction in
                        transaction.animation = nil
                        transaction.disablesAnimations = true
                    }
                TheoryHelpButton(
                    titleKey: "Надстройки аккорда",
                    bodyKey: "Справка: надстройки аккорда"
                )
            }

            if store.areChordExtensionsVisible {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 64), spacing: 8)], spacing: 8) {
                    ForEach(availableChordExtensions) { item in
                        let isSelected = store.chordSettings.extensions.contains(item)
                        Button {
                            toggleChordExtension(item)
                        } label: {
                            Text(item.title)
                                .font(.system(.caption, design: .rounded).weight(.black))
                                .frame(maxWidth: .infinity)
                                .frame(height: 34)
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(isSelected ? Color.white : AppColors.primaryText)
                        .background(
                            isSelected ? AppColors.rootText : AppColors.control.opacity(0.8),
                            in: RoundedRectangle(cornerRadius: 8, style: .continuous)
                        )
                    }
                }
            }
        }
    }

    private var compactChordExtensionsPicker: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Toggle("Надстройки", isOn: noAnimationBinding($store.areChordExtensionsVisible))
                    .toggleStyle(.switch)
                    .font(.system(.caption, design: .rounded).weight(.semibold))
                    .foregroundStyle(AppColors.primaryText)
                    .tint(AppColors.rootText)
                    .transaction { transaction in
                        transaction.animation = nil
                        transaction.disablesAnimations = true
                    }
                TheoryHelpButton(
                    titleKey: "Надстройки аккорда",
                    bodyKey: "Справка: надстройки аккорда"
                )
            }

            if store.areChordExtensionsVisible {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 50), spacing: 6)], spacing: 6) {
                    ForEach(availableChordExtensions) { item in
                        let isSelected = store.chordSettings.extensions.contains(item)
                        Button {
                            toggleChordExtension(item)
                        } label: {
                            Text(item.title)
                                .font(.system(.caption2, design: .rounded).weight(.black))
                                .frame(maxWidth: .infinity)
                                .frame(height: 30)
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(isSelected ? Color.white : AppColors.primaryText)
                        .background(
                            isSelected ? AppColors.rootText : AppColors.control.opacity(0.8),
                            in: RoundedRectangle(cornerRadius: 7, style: .continuous)
                        )
                    }
                }
            }
        }
    }

    private var fretStepper: some View {
        Stepper("Лады: \(store.fretCount)", value: noAnimationBinding($store.fretCount), in: 12...24, step: 1)
            .foregroundStyle(AppColors.primaryText)
            .tint(AppColors.primaryText)
    }

    private func degreeNumbersToggle(for mode: AppMode) -> some View {
        Toggle("Ступени", isOn: degreeNumbersBinding(for: mode))
            .toggleStyle(.switch)
            .font(.system(.subheadline, design: .rounded).weight(.semibold))
            .foregroundStyle(AppColors.primaryText)
            .tint(AppColors.rootText)
            .transaction { transaction in
                transaction.animation = nil
                transaction.disablesAnimations = true
            }
    }

    private func degreeColorsToggle(for mode: AppMode) -> some View {
        Toggle("Выделить ступени цветом", isOn: degreeColorsBinding(for: mode))
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
    private var scaleBoxesToggle: some View {
        if selectedScale.supportsBoxes {
            VStack(alignment: .leading, spacing: 10) {
                Toggle("Показать боксы", isOn: noAnimationBinding($store.showsScaleBoxes))
                    .toggleStyle(.switch)
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .foregroundStyle(AppColors.primaryText)
                    .tint(AppColors.rootText)
                    .transaction { transaction in
                        transaction.animation = nil
                        transaction.disablesAnimations = true
                    }

                if store.showsScaleBoxes {
                    HStack(spacing: 8) {
                        ForEach(selectedScale.boxes) { box in
                            Text("\(box.index + 1)")
                                .font(.system(.caption2, design: .rounded).weight(.black))
                                .foregroundStyle(.white)
                                .frame(width: 28, height: 22)
                                .background(box.color, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                        }
                    }
                }
            }
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
            .appSurface(fill: AppColors.elevatedPanel, castsShadow: true)
        }
    }

    @ViewBuilder
    private var chordShapeCounterOverlay: some View {
        let shapes = availableChordShapes
        if shapes.count > 1, let index = selectedChordShapeIndex {
            VStack(spacing: 8) {
                Button {
                    selectChordShape(offset: 1)
                } label: {
                    Image(systemName: "chevron.up")
                        .font(.system(size: 13, weight: .black))
                        .frame(width: 32, height: 24)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Следующая форма аккорда")

                Text("\(index + 1) / \(shapes.count)")
                    .font(.system(.headline, design: .rounded).weight(.black))
                    .monospacedDigit()

                Button {
                    selectChordShape(offset: -1)
                } label: {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 13, weight: .black))
                        .frame(width: 32, height: 24)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Предыдущая форма аккорда")
            }
            .foregroundStyle(AppColors.primaryText)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .appSurface(fill: AppColors.elevatedPanel, castsShadow: true)
        }
    }

    private var scaleSummary: String {
        selectedScale.intervals.map { interval in
            MusicNoteSpeller.scaleNoteName(
                pitchClass: interval + store.rootNote,
                tonicPitchClass: store.rootNote,
                scale: selectedScale,
                preferredNames: noteNames
            )
        }.joined(separator: "  ")
    }

    private var scaleMarkers: [FretMarker] {
        makeMarkers { stringIndex, fret, pitch in
            guard selectedScale.intervals.contains((pitch - store.rootNote + 12) % 12),
                  let degree = selectedScale.degreeLabel(for: pitch, root: store.rootNote) else { return nil }
            let noteName = MusicNoteSpeller.scaleNoteName(
                pitchClass: pitch,
                tonicPitchClass: store.rootNote,
                scale: selectedScale,
                preferredNames: noteNames
            )
            let label = showsDegreeNumbers ? "\(noteName)/\(degree)" : noteName
            return FretMarker(
                position: FretPosition(stringIndex: stringIndex, fret: fret),
                label: label,
                isRoot: pitch == store.rootNote,
                color: store.highlightsScaleDegrees ? degreeColor(for: degree) : nil
            )
        }
    }

    private func scaleBoxColor(forFret fret: Int) -> Color? {
        guard store.showsScaleBoxes, selectedScale.supportsBoxes else { return nil }
        let boxes = selectedScale.boxes
        guard !boxes.isEmpty else { return nil }

        let rootFret = scaleRootFretOnLowestString
        let relativeFret = (fret - rootFret + 120) % 12
        let starts = scaleBoxStartIntervals
        let boxIndex = starts.lastIndex(where: { relativeFret >= $0 }) ?? 0
        return boxes[min(boxIndex, boxes.count - 1)].color
    }

    private var scaleRootFretOnLowestString: Int {
        guard let lowestString = selectedTuning(for: .modes).strings.first else { return 0 }
        return (store.rootNote - lowestString.pitchClass + 12) % 12
    }

    private var scaleBoxStartIntervals: [Int] {
        if selectedScale.intervals.count == 5 {
            return Array(selectedScale.intervals.prefix(5))
        }
        return [0, 2, 4, 7, 9]
    }

    private var appliedChordSettings: ChordSettings {
        var settings = store.chordSettings
        if !store.areChordExtensionsVisible {
            settings.extensions = []
        }
        return settings
    }

    private var chordMarkers: [FretMarker] {
        guard store.chordStringCount >= 6 else { return [] }

        if let cagedMarkers = cagedChordMarkers {
            return cagedMarkers
        }

        let settings = appliedChordSettings
        let intervals = settings.intervals
        return makeMarkers { stringIndex, fret, pitch in
            let guitarStringNumber = stringIndex + 1
            guard guitarStringNumber <= settings.startString else { return nil }
            let interval = (pitch - settings.root + 12) % 12
            guard intervals.contains(interval) else { return nil }
            let degree = settings.toneLabel(for: interval) ?? ""
            let noteName = MusicNoteSpeller.noteName(
                pitchClass: pitch,
                tonicPitchClass: settings.root,
                degreeLabel: degree,
                preferredNames: noteNames
            )
            let label = showsDegreeNumbers ? "\(noteName)/\(degree)" : noteName
            return FretMarker(
                position: FretPosition(stringIndex: stringIndex, fret: fret),
                label: label,
                isRoot: interval == 0,
                color: store.chordHighlightsDegrees ? degreeColor(for: degree) : nil
            )
        }
    }

    private var chordBarres: [ChordBarre] {
        guard usesCagedChordShape, let shape = selectedChordShape else { return [] }
        return shape.transposedBarres(to: appliedChordSettings.root)
    }

    private var chordVisibleFretRange: ClosedRange<Int>? {
        guard usesCagedChordShape else { return nil }
        let markerFrets = chordMarkers.map { $0.position.fret }
        let barreFrets = chordBarres.map(\.fret)
        let frets = markerFrets + barreFrets
        guard let minFret = frets.min(), let maxFret = frets.max() else { return nil }

        if minFret == 0 {
            return 0...min(store.chordFretCount, max(maxFret + 1, 4))
        }

        let start = max(1, minFret - 1)
        let end = min(store.chordFretCount, max(maxFret + 1, start + 3))
        return start...end
    }

    private var cagedChordMarkers: [FretMarker]? {
        guard usesCagedChordShape, let shape = selectedChordShape else { return nil }
        let settings = appliedChordSettings
        let displayedStrings = Array(selectedTuning(for: .chords).strings.reversed())
        return shape.transposedNotes(to: settings.root).compactMap { note in
            let stringIndex = note.stringNumber - 1
            guard displayedStrings.indices.contains(stringIndex), (0...store.chordFretCount).contains(note.fret) else { return nil }
            let pitch = (displayedStrings[stringIndex].pitchClass + note.fret) % 12
            let interval = (pitch - settings.root + 12) % 12
            let degree = settings.toneLabel(for: interval) ?? (interval == 9 ? "bb7" : "")
            let noteName = MusicNoteSpeller.noteName(
                pitchClass: pitch,
                tonicPitchClass: settings.root,
                degreeLabel: degree,
                preferredNames: noteNames
            )
            let label = showsDegreeNumbers && !degree.isEmpty ? "\(noteName)/\(degree)" : noteName
            return FretMarker(
                position: FretPosition(stringIndex: stringIndex, fret: note.fret),
                label: label,
                isRoot: interval == 0,
                color: store.chordHighlightsDegrees ? degreeColor(for: degree) : nil
            )
        }
    }

    private func degreeColor(for label: String) -> Color? {
        let digits = label.filter(\.isNumber)
        guard let rawDegree = Int(digits), rawDegree > 0 else { return nil }
        let degree = ((rawDegree - 1) % 7) + 1

        switch degree {
        case 1: return Color(red: 0.18, green: 0.50, blue: 0.92)
        case 2: return Color(red: 0.12, green: 0.67, blue: 0.67)
        case 3: return Color(red: 0.20, green: 0.66, blue: 0.38)
        case 4: return Color(red: 0.82, green: 0.66, blue: 0.16)
        case 5: return Color(red: 0.91, green: 0.43, blue: 0.16)
        case 6: return Color(red: 0.57, green: 0.38, blue: 0.86)
        case 7: return Color(red: 0.78, green: 0.27, blue: 0.52)
        default: return nil
        }
    }

    private var usesCagedChordShape: Bool {
        selectedChordShape != nil
    }

    private var availableChordShapes: [ChordShape] {
        let settings = appliedChordSettings
        if store.chordIsCustomTuningEnabled || settings.hasExtensions || !supportsCagedChordShapes {
            return chordShapeGenerator.generateShapes()
        }

        let databaseShapes = ChordFingeringDatabase.shapes(
            quality: settings.quality,
            size: settings.size,
            maxRootString: store.chordStringCount
        )
        return databaseShapes.isEmpty ? chordShapeGenerator.generateShapes() : databaseShapes
    }

    private var chordShapeGenerator: ChordShapeGenerator {
        ChordShapeGenerator(
            settings: appliedChordSettings,
            tuning: selectedTuning(for: .chords),
            fretCount: store.chordFretCount,
            stringCount: store.chordStringCount
        )
    }

    private var supportsCagedChordShapes: Bool {
        chordShapeGenerator.supportsCAGEDShapes
    }

    private var availableChordSizes: [ChordSize] {
        ChordSize.available(for: store.chordSettings.quality)
    }

    private var availableChordExtensions: [ChordExtension] {
        ChordExtension.allCases.filter { $0.isAvailable(for: store.chordSettings) }
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
        let settings = appliedChordSettings
        return "\(noteNames[settings.root])\(settings.displaySuffix)"
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
        let validExtensions = store.chordSettings.extensions.filter { $0.isAvailable(for: store.chordSettings) }
        if validExtensions != store.chordSettings.extensions {
            store.chordSettings.extensions = validExtensions
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

    private func toggleChordExtension(_ item: ChordExtension) {
        noAnimation {
            if store.chordSettings.extensions.contains(item) {
                store.chordSettings.extensions.removeAll { $0 == item }
            } else {
                store.chordSettings.extensions.append(item)
            }
            syncChordShape()
        }
    }

    private func makeMarkers(_ builder: (Int, Int, Int) -> FretMarker?) -> [FretMarker] {
        let displayedStrings = Array(selectedTuning.strings.reversed())
        var markers: [FretMarker] = []
        for stringIndex in displayedStrings.indices {
            let string = displayedStrings[stringIndex]
            for fret in 0...activeFretCount {
                let pitch = (string.pitchClass + fret) % 12
                if let marker = builder(stringIndex, fret, pitch) {
                    markers.append(marker)
                }
            }
        }
        return markers
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
            get: { max(store.chordStringCount, 6) },
            set: { newValue in
                noAnimation { setChordStringCount(max(newValue, 6)) }
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

    private func openMode(_ mode: AppMode) {
        noAnimation {
            store.appMode = mode
            isModeSelectionVisible = false
            if mode == .chords {
                ensureChordStringCount()
            } else if mode == .harmony, store.harmonyMode == .popular {
                store.popularCollectionMode = .popular
            }
        }
        updateSupportedOrientations(for: mode)
    }

    private func returnToModeSelection() {
        noAnimation {
            store.isCustomMode = false
            customTuningTargetMode = nil
            isModeSelectionVisible = true
        }
        AppOrientationController.setSupportedOrientations(.allButUpsideDown)
    }

    private func supportedOrientations(for mode: AppMode) -> UIInterfaceOrientationMask {
        .allButUpsideDown
    }

    private func updateSupportedOrientations(for mode: AppMode) {
        AppOrientationController.setSupportedOrientations(supportedOrientations(for: mode))
    }

    private func compatibleTunings(for mode: AppMode) -> [TuningPreset] {
        tuningCatalog.compatibleTunings(stringCount: stringCount(for: mode))
    }

    private func customTunings(for mode: AppMode) -> [CustomTuningPreset] {
        tuningCatalog.customTunings(
            stringCount: stringCount(for: mode),
            from: store.customTuningPresets
        )
    }

    private func selectedCustomTuning(for mode: AppMode) -> CustomTuningPreset? {
        let stringCount = stringCount(for: mode)
        let selectedID = mode == .chords ? store.chordSelectedCustomTuningID : store.selectedCustomTuningID
        return tuningCatalog.selectedCustomTuning(
            id: selectedID,
            stringCount: stringCount,
            from: store.customTuningPresets
        )
    }

    private func selectedTuning(for mode: AppMode) -> TuningPreset {
        let stringCount = stringCount(for: mode)
        return tuningCatalog.resolveTuning(
            stringCount: stringCount,
            builtInID: mode == .chords ? store.chordSelectedTuningID : store.selectedTuningID,
            customID: mode == .chords ? store.chordSelectedCustomTuningID : store.selectedCustomTuningID,
            customPresets: store.customTuningPresets,
            noteNames: noteNames(for: mode)
        )
    }

    private func stringCount(for mode: AppMode) -> Int {
        mode == .chords ? store.chordStringCount : store.stringCount
    }

    private func noteNames(for mode: AppMode) -> [String] {
        (mode == .chords ? store.chordAccidentalStyle : store.accidentalStyle).noteNames
    }

    private func tuningSelectionBinding(for mode: AppMode) -> Binding<String> {
        Binding(
            get: {
                if let selectedCustomTuning = selectedCustomTuning(for: mode) {
                    return tuningCatalog.menuID(forCustomTuningID: selectedCustomTuning.id)
                }
                return selectedTuning(for: mode).id
            },
            set: { newValue in
                noAnimation {
                    if newValue == manageCustomTuningID {
                        customTuningTargetMode = mode
                    } else if let customID = tuningCatalog.customTuningID(fromMenuID: newValue) {
                        setSelectedCustomTuning(customID, for: mode)
                        syncChordShape()
                    } else {
                        setSelectedBuiltInTuning(newValue, for: mode)
                        syncChordShape()
                    }
                }
            }
        )
    }

    private func noAnimationBinding<Value>(_ binding: Binding<Value>) -> Binding<Value> {
        Binding(get: { binding.wrappedValue }, set: { value in noAnimation { binding.wrappedValue = value } })
    }

    private func accidentalStyleBinding(for mode: AppMode) -> Binding<AccidentalStyle> {
        Binding(
            get: { mode == .chords ? store.chordAccidentalStyle : store.accidentalStyle },
            set: { newValue in
                noAnimation {
                    if mode == .chords {
                        store.chordAccidentalStyle = newValue
                    } else {
                        store.accidentalStyle = newValue
                    }
                }
            }
        )
    }

    private func degreeNumbersBinding(for mode: AppMode) -> Binding<Bool> {
        Binding(
            get: { mode == .chords ? store.chordShowsDegreeNumbers : store.showsDegreeNumbers },
            set: { newValue in
                noAnimation {
                    if mode == .chords {
                        store.chordShowsDegreeNumbers = newValue
                    } else {
                        store.showsDegreeNumbers = newValue
                    }
                }
            }
        )
    }

    private func degreeColorsBinding(for mode: AppMode) -> Binding<Bool> {
        Binding(
            get: { mode == .chords ? store.chordHighlightsDegrees : store.highlightsScaleDegrees },
            set: { newValue in
                noAnimation {
                    if mode == .chords {
                        store.chordHighlightsDegrees = newValue
                    } else {
                        store.highlightsScaleDegrees = newValue
                    }
                }
            }
        )
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
        ensureChordStringCount()
        syncChordShape()
    }

    private func ensureChordStringCount() {
        if store.chordStringCount < 6 {
            setChordStringCount(6)
        }
    }

    private func setStringCount(_ count: Int) {
        let previousCustomTuningID = store.selectedCustomTuningID
        store.stringCount = count
        if let previousCustomTuningID,
           !store.customTuningPresets.contains(where: { $0.id == previousCustomTuningID && $0.stringCount == count }) {
            store.selectedCustomTuningID = nil
            store.isCustomTuningEnabled = false
        }
        store.chordSettings.startString = min(store.chordSettings.startString, count)
        let tuningsForCount = tuningCatalog.compatibleTunings(stringCount: count)
        guard let firstTuning = tuningsForCount.first else { return }
        if !tuningsForCount.contains(where: { $0.id == store.selectedTuningID }) {
            store.selectedTuningID = firstTuning.id
        }
        syncChordShape()
    }

    private func setChordStringCount(_ count: Int) {
        let count = max(count, 6)
        let previousCustomTuningID = store.chordSelectedCustomTuningID
        store.chordStringCount = count
        if let previousCustomTuningID,
           !store.customTuningPresets.contains(where: { $0.id == previousCustomTuningID && $0.stringCount == count }) {
            store.chordSelectedCustomTuningID = nil
            store.chordIsCustomTuningEnabled = false
        }
        store.chordSettings.startString = min(store.chordSettings.startString, count)
        let tuningsForCount = tuningCatalog.compatibleTunings(stringCount: count)
        guard let firstTuning = tuningsForCount.first else { return }
        if !tuningsForCount.contains(where: { $0.id == store.chordSelectedTuningID }) {
            store.chordSelectedTuningID = firstTuning.id
        }
        syncChordShape()
    }

    private func setSelectedCustomTuning(_ customID: String, for mode: AppMode) {
        if mode == .chords {
            store.chordSelectedCustomTuningID = customID
            store.chordIsCustomTuningEnabled = true
        } else {
            store.selectedCustomTuningID = customID
            store.isCustomTuningEnabled = true
        }
    }

    private func setSelectedBuiltInTuning(_ tuningID: String, for mode: AppMode) {
        if mode == .chords {
            store.chordSelectedCustomTuningID = nil
            store.chordIsCustomTuningEnabled = false
            store.chordSelectedTuningID = tuningID
        } else {
            store.selectedCustomTuningID = nil
            store.isCustomTuningEnabled = false
            store.selectedTuningID = tuningID
        }
    }

    private func defaultTuningPitchClasses(for stringCount: Int) -> [Int] {
        tuningCatalog.defaultPitchClasses(stringCount: stringCount)
    }

    private func saveCustomTuning(_ preset: CustomTuningPreset) {
        if let index = store.customTuningPresets.firstIndex(where: { $0.id == preset.id }) {
            var presets = store.customTuningPresets
            presets[index] = preset
            store.customTuningPresets = presets
        } else {
            store.customTuningPresets.append(preset)
        }

        guard let customTuningTargetMode else { return }
        setSelectedCustomTuning(preset.id, for: customTuningTargetMode)
        syncChordShape()
    }

    private func deleteCustomTuning(_ preset: CustomTuningPreset) {
        store.customTuningPresets.removeAll { $0.id == preset.id }
        if store.selectedCustomTuningID == preset.id {
            store.selectedCustomTuningID = nil
            store.isCustomTuningEnabled = false
        }
        if store.chordSelectedCustomTuningID == preset.id {
            store.chordSelectedCustomTuningID = nil
            store.chordIsCustomTuningEnabled = false
        }
        syncChordShape()
    }
}

struct HomeCoordinatorView_Previews: PreviewProvider {
    static var previews: some View {
        HomeCoordinatorView(
            store: AppSettingsStore(),
            customTuningTargetMode: .constant(nil),
            isCreatingSavedProgression: .constant(false)
        )
    }
}
