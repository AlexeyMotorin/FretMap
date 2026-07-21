import SwiftUI
import UIKit

struct AppBackgroundView: View {
    var body: some View {
        ZStack {
            Color(red: 0.025, green: 0.07, blue: 0.13)
            Image("Background")
                .resizable()
                .scaledToFill()
        }
        .ignoresSafeArea()
    }
}

struct ContentView: View {
    @StateObject private var store = AppSettingsStore()
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @State private var isModeSelectionVisible = true
    @State private var isCustomTuningSheetPresented = false
    @State private var editingCustomTuningID: String?
    @State private var customTuningDraftName = ""
    @State private var customTuningDraftPitchClasses: [Int] = []
    @State private var customTuningTargetMode: AppMode = .modes
    @FocusState private var isCustomTuningNameFocused: Bool

    private let scales = ScalePattern.all
    private let tunings = TuningPreset.all
    private let manageCustomTuningID = "__manage_custom_tuning__"
    // Temporarily disabled while the custom chord workflow is being revised.
    private let isCustomModeAvailable = false
    // Temporarily disabled while scale box behavior is being revised.
    private let areScaleBoxesAvailable = false

    private var noteNames: [String] { noteNames(for: store.appMode == .chords || store.isCustomMode ? .chords : .modes) }
    private var customTuningNoteNames: [String] { noteNames(for: customTuningTargetMode) }
    private var showsDegreeNumbers: Bool { store.appMode == .chords || store.isCustomMode ? store.chordShowsDegreeNumbers : store.showsDegreeNumbers }
    private var selectedScale: ScalePattern { scales.first { $0.id == store.selectedScaleID } ?? .ionian }
    private var activeFretCount: Int { store.appMode == .chords || store.isCustomMode ? store.chordFretCount : store.fretCount }
    private var activeTuningStringCount: Int { customTuningTargetMode == .chords ? store.chordStringCount : store.stringCount }
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
                        modeSelectionView(containerSize: proxy.size)
                            .transition(.identity)
                    } else if isCustomModeAvailable && store.isCustomMode {
                        customModeView
                            .frame(width: proxy.size.width, height: proxy.size.height)
                    } else {
                        ZStack(alignment: .topLeading) {
                            content
                                .frame(width: proxy.size.width, height: proxy.size.height, alignment: .topLeading)
                                .clipped()
                                .transition(.identity)

                            modeBackButton
                                .padding(12)
                                .zIndex(10)
                        }
                        .id("\(store.appMode.rawValue)-\(isPortraitLayout ? "portrait" : "landscape")")
                        .frame(width: proxy.size.width, height: proxy.size.height, alignment: .topLeading)
                        .clipped()
                    }

                    if isCustomTuningSheetPresented {
                        customTuningWindow(containerSize: proxy.size)
                            .zIndex(40)
                            .transition(.identity)
                    }
            }
            .frame(width: proxy.size.width, height: proxy.size.height, alignment: .topLeading)
        }
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
        .onChange(of: isCustomTuningSheetPresented) { isPresented in
            AppOrientationController.setSupportedOrientations(
                isPresented ? .portrait : supportedOrientations(for: store.appMode)
            )
        }
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
        }
    }

    private func modeSelectionView(containerSize: CGSize) -> some View {
        Group {
            if isPortraitLayout {
                VStack(spacing: 14) {
                    Spacer(minLength: 30)
                    modeSelectionButtons
                        .frame(maxWidth: 340)

                    Image("Logo")
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 300)
                        .padding(.top, 14)
                        .accessibilityHidden(true)
                    Spacer(minLength: 30)
                }
            } else {
                HStack(spacing: 32) {
                    modeSelectionButtons
                        .frame(width: 300)

                    Image("Logo")
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 300, maxHeight: 230)
                        .accessibilityHidden(true)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .padding(.horizontal, 24)
        .frame(width: containerSize.width, height: containerSize.height)
    }

    private var modeSelectionButtons: some View {
        VStack(spacing: 10) {
            modeSelectionButton(.chords, systemName: "music.note")
            modeSelectionButton(.modes, systemName: "guitars")
            modeSelectionButton(.harmony, systemName: "music.note.list")
        }
    }

    private func modeSelectionButton(_ mode: AppMode, systemName: String) -> some View {
        Button {
            openMode(mode)
        } label: {
            Label(mode.title, systemImage: systemName)
                .font(.system(.headline, design: .rounded).weight(.black))
                .foregroundStyle(AppColors.primaryText)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(AppColors.panel.opacity(0.94), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(AppColors.control, lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
    }

    private var modeBackButton: some View {
        Button(action: returnToModeSelection) {
            Image(systemName: "chevron.left")
                .font(.system(size: 16, weight: .black))
                .foregroundStyle(AppColors.primaryText)
                .frame(width: 40, height: 36)
                .background(AppColors.control.opacity(0.96), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Назад к выбору режима")
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
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .clipped()
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
        GeometryReader { proxy in
            let isPortrait = isPortraitLayout

            VStack(spacing: 0) {
                Picker("Гармония", selection: noAnimationBinding($store.harmonyMode)) {
                    ForEach(HarmonyMode.allCases) { mode in
                        if isPortrait {
                            Image(systemName: harmonyModeIcon(for: mode))
                                .accessibilityLabel(mode.title)
                                .tag(mode)
                        } else {
                            Text(mode.title).tag(mode)
                        }
                    }
                }
                .pickerStyle(.segmented)
                .font(isPortrait ? .caption : .body)
                .padding(isPortrait ? 8 : 12)
                .padding(.leading, 52)

                Group {
                    switch store.harmonyMode {
                    case .functional:
                        FunctionalHarmonyView(noteNames: noteNames, store: store)
                    case .modal:
                        ModalHarmonyView(noteNames: noteNames, store: store)
                    case .popular:
                        PopularHarmonyView(noteNames: noteNames, store: store)
                    case .saved:
                        SavedHarmonyView(noteNames: noteNames, store: store)
                    }
                }
                .frame(width: proxy.size.width, alignment: .topLeading)
                .frame(maxHeight: .infinity, alignment: .topLeading)
                .clipped()
            }
        }
        .ignoresSafeArea(.container, edges: .bottom)
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
        .background(AppColors.panel)
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
                    Button { setSettingsVisible(false) } label: {
                        Image(systemName: "gearshape.fill")
                            .foregroundStyle(AppColors.primaryText)
                            .frame(width: 36, height: 36)
                            .background(AppColors.control, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.leading, 48)

                notePicker(title: "Тональность", selection: noAnimationBinding($store.rootNote))

                UIKitMenuPicker(title: "Лад", selection: noAnimationBinding($store.selectedScaleID), options: scales.map { MenuPickerItem(value: $0.id, title: $0.name) })
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
    }

    private var customModeView: some View {
        ZStack(alignment: .topLeading) {
            FretboardView(
                tuning: selectedTuning,
                fretCount: store.chordFretCount,
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
            MenuPickerItem(value: customTuningMenuID(for: preset.id), title: preset.name)
        }
        return builtIn + custom + [MenuPickerItem(value: manageCustomTuningID, title: "Создать строй")]
    }

    private func customTuningWindow(containerSize: CGSize) -> some View {
        ZStack {
            KeyboardDismissTapObserver {
                dismissKeyboard()
            }
            .frame(width: 0, height: 0)

            AppBackgroundView()
                .contentShape(Rectangle())
                .onTapGesture {
                    dismissKeyboard()
                }

            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    Text("Создать строй")
                        .font(.system(.title3, design: .rounded).weight(.black))
                        .foregroundStyle(AppColors.primaryText)

                    Spacer()

                    Button {
                        noAnimation { isCustomTuningSheetPresented = false }
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 15, weight: .black))
                            .foregroundStyle(AppColors.primaryText)
                            .frame(width: 38, height: 38)
                            .background(AppColors.control.opacity(0.95), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 12)

                ScrollView(.vertical) {
                    VStack(alignment: .leading, spacing: 14) {
                        if !customTuningsForTargetMode.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Сохраненные")
                                    .font(.system(.caption, design: .rounded).weight(.bold))
                                    .foregroundStyle(AppColors.mutedText)

                                ForEach(customTuningsForTargetMode) { preset in
                                    customTuningPresetRow(preset)
                                }
                            }
                        }

                        VStack(alignment: .leading, spacing: 10) {
                            Text(editingCustomTuningID == nil ? "Новый строй" : "Редактирование")
                                .font(.system(.headline, design: .rounded).weight(.bold))
                                .foregroundStyle(AppColors.primaryText)

                            TextField("", text: $customTuningDraftName, prompt: Text("Название строя").foregroundColor(AppColors.mutedText))
                                .textFieldStyle(.plain)
                                .foregroundStyle(AppColors.primaryText)
                                .focused($isCustomTuningNameFocused)
                                .padding(.horizontal, 14)
                                .frame(height: 44)
                                .background(AppColors.control.opacity(0.9), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

                            ForEach(0..<activeTuningStringCount, id: \.self) { visualIndex in
                                let storageIndex = activeTuningStringCount - 1 - visualIndex
                                HStack(spacing: 10) {
                                    Text("Струна \(visualIndex + 1): \(customTuningPitchName(storageIndex: storageIndex))")
                                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                                        .foregroundStyle(AppColors.primaryText)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.78)

                                    Spacer()

                                    semitoneButton(systemName: "arrow.down", label: "Опустить струну \(visualIndex + 1)") {
                                        shiftCustomTuningPitch(storageIndex: storageIndex, by: -1)
                                    }

                                    semitoneButton(systemName: "arrow.up", label: "Поднять струну \(visualIndex + 1)") {
                                        shiftCustomTuningPitch(storageIndex: storageIndex, by: 1)
                                    }
                                }
                                .padding(.horizontal, 14)
                                .frame(height: 40)
                                .background(AppColors.control.opacity(0.9), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                            }
                        }
                        .padding(12)
                        .background(AppColors.panel.opacity(0.95), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

                        allStringsSemitoneControl
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 18)
                }
                .scrollDismissesKeyboard(.interactively)
                .simultaneousGesture(
                    DragGesture(minimumDistance: 8)
                        .onChanged { _ in
                            dismissKeyboard()
                        }
                )

                HStack(spacing: 12) {
                    Button {
                        resetCustomTuningDraft()
                    } label: {
                        Text("Сбросить")
                            .font(.system(.subheadline, design: .rounded).weight(.bold))
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                    }
                    .buttonStyle(.bordered)

                    Button {
                        saveCustomTuningDraft()
                    } label: {
                        Text("OK")
                            .font(.system(.subheadline, design: .rounded).weight(.black))
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(customTuningDraftName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 18)
                .padding(.top, 10)
            }
            .frame(maxWidth: 430)
            .background(AppColors.panel.opacity(0.88))
            .padding(.horizontal, 16)
        }
        .frame(width: containerSize.width, height: containerSize.height)
        .clipped()
        .transaction { transaction in
            transaction.animation = nil
            transaction.disablesAnimations = true
        }
    }

    private func customTuningPresetRow(_ preset: CustomTuningPreset) -> some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 3) {
                Text(preset.name)
                    .font(.system(.subheadline, design: .rounded).weight(.bold))
                    .foregroundStyle(AppColors.primaryText)
                Text(tuningSummary(for: preset.pitchClasses))
                    .font(.system(.caption, design: .rounded).weight(.semibold))
                    .foregroundStyle(AppColors.mutedText)
                    .lineLimit(1)
            }

            Spacer()

            Button {
                editCustomTuning(preset)
            } label: {
                Image(systemName: "pencil")
                    .font(.system(size: 15, weight: .bold))
                    .frame(width: 34, height: 34)
            }
            .buttonStyle(.bordered)

            Button {
                deleteCustomTuning(preset)
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 15, weight: .bold))
                    .frame(width: 34, height: 34)
            }
            .buttonStyle(.bordered)
            .tint(.red)
        }
        .padding(10)
        .background(AppColors.control.opacity(0.55), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var allStringsSemitoneControl: some View {
        HStack(spacing: 10) {
            Text("Все струны")
                .font(.system(.subheadline, design: .rounded).weight(.bold))
                .foregroundStyle(AppColors.primaryText)

            Spacer()

            semitoneButton(systemName: "arrow.down", label: "Опустить все") {
                shiftAllCustomTuningPitches(by: -1)
            }

            semitoneButton(systemName: "arrow.up", label: "Поднять все") {
                shiftAllCustomTuningPitches(by: 1)
            }
        }
        .padding(.horizontal, 14)
        .frame(height: 44)
        .background(AppColors.control.opacity(0.72), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func semitoneButton(systemName: String, label: String, action: @escaping () -> Void) -> some View {
        Button {
            noAnimation(action)
        } label: {
            Image(systemName: systemName)
                .font(.system(size: 15, weight: .black))
                .foregroundStyle(AppColors.primaryText)
                .frame(width: 38, height: 32)
                .background(AppColors.panel.opacity(0.9), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
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
            Toggle("Надстройки", isOn: noAnimationBinding($store.areChordExtensionsVisible))
                .toggleStyle(.switch)
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .foregroundStyle(AppColors.primaryText)
                .tint(AppColors.rootText)
                .transaction { transaction in
                    transaction.animation = nil
                    transaction.disablesAnimations = true
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
            Toggle("Надстройки", isOn: noAnimationBinding($store.areChordExtensionsVisible))
                .toggleStyle(.switch)
                .font(.system(.caption, design: .rounded).weight(.semibold))
                .foregroundStyle(AppColors.primaryText)
                .tint(AppColors.rootText)
                .transaction { transaction in
                    transaction.animation = nil
                    transaction.disablesAnimations = true
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
            .background(AppColors.panel.opacity(0.94), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
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
            let label = showsDegreeNumbers ? "\(noteNames[pitch])/\(degree)" : noteNames[pitch]
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
            let label = showsDegreeNumbers ? "\(noteNames[pitch])/\(degree)" : noteNames[pitch]
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
            let label = showsDegreeNumbers && !degree.isEmpty ? "\(noteNames[pitch])/\(degree)" : noteNames[pitch]
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
            return generatedChordShapes
        }

        let databaseShapes = ChordFingeringDatabase.shapes(
            quality: settings.quality,
            size: settings.size,
            maxRootString: store.chordStringCount
        )
        return databaseShapes.isEmpty ? generatedChordShapes : databaseShapes
    }

    private var generatedChordShapes: [ChordShape] {
        guard store.chordStringCount >= 4 else { return [] }
        return Array((4...store.chordStringCount).reversed()).compactMap { rootString in
            generatedChordShape(rootString: rootString)
        }
    }

    private func generatedChordShape(rootString: Int) -> ChordShape? {
        let settings = appliedChordSettings
        let displayedStrings = Array(selectedTuning(for: .chords).strings.reversed())
        let rootIndex = rootString - 1
        guard displayedStrings.indices.contains(rootIndex) else { return nil }

        let maxRootFret = min(store.chordFretCount, 12)
        guard let rootFret = (0...maxRootFret).first(where: {
            (displayedStrings[rootIndex].pitchClass + $0) % 12 == settings.root
        }) else {
            return nil
        }

        let intervalSet = settings.intervals
        let requiredIntervals = settings.requiredIntervals
        let stringNumbers = Array(max(1, rootString - 4)...rootString)
        var notes: [ChordShape.Note] = [ChordShape.Note(stringNumber: rootString, fret: rootFret)]
        var coveredIntervals: Set<Int> = [0]

        for stringNumber in stringNumbers where stringNumber != rootString {
            guard let note = bestGeneratedNote(
                stringNumber: stringNumber,
                rootFret: rootFret,
                coveredIntervals: coveredIntervals,
                displayedStrings: displayedStrings,
                allowedIntervals: intervalSet
            ) else { continue }

            let pitch = (displayedStrings[stringNumber - 1].pitchClass + note.fret) % 12
            let interval = (pitch - settings.root + 12) % 12
            notes.append(note)
            coveredIntervals.insert(interval)
        }

        guard requiredIntervals.isSubset(of: coveredIntervals) else { return nil }

        return ChordShape(
            id: "generated-\(settings.root)-\(settings.quality.rawValue)-\(settings.size.rawValue)-\(settings.extensions.map(\.rawValue).joined(separator: "-"))-\(rootString)-\(rootFret)",
            title: "Кастом от \(rootString) струны",
            quality: settings.quality,
            size: settings.size,
            rootString: rootString,
            baseRoot: settings.root,
            notes: notes.sorted { $0.stringNumber < $1.stringNumber },
            barres: []
        )
    }

    private func bestGeneratedNote(
        stringNumber: Int,
        rootFret: Int,
        coveredIntervals: Set<Int>,
        displayedStrings: [GuitarString],
        allowedIntervals: Set<Int>
    ) -> ChordShape.Note? {
        let stringIndex = stringNumber - 1
        guard displayedStrings.indices.contains(stringIndex) else { return nil }

        let startFret = max(0, rootFret - 2)
        let endFret = min(store.chordFretCount, rootFret + 5)
        let candidates = (startFret...endFret).compactMap { fret -> (note: ChordShape.Note, score: Int)? in
            let pitch = (displayedStrings[stringIndex].pitchClass + fret) % 12
            let interval = (pitch - appliedChordSettings.root + 12) % 12
            guard allowedIntervals.contains(interval) else { return nil }
            let duplicatePenalty = coveredIntervals.contains(interval) ? 80 : 0
            let distancePenalty = abs(fret - rootFret) * 4
            let openStringBonus = fret == 0 ? -3 : 0
            return (ChordShape.Note(stringNumber: stringNumber, fret: fret), duplicatePenalty + distancePenalty + openStringBonus)
        }

        return candidates.min { $0.score < $1.score }?.note
    }

    private var supportsCagedChordShapes: Bool {
        let standardTopSix = [4, 9, 2, 7, 11, 4]
        return selectedTuning(for: .chords).strings.suffix(6).map(\.pitchClass) == standardTopSix
    }

    private var availableChordSizes: [ChordSize] {
        ChordSize.available(for: store.chordSettings.quality)
    }

    private var availableChordExtensions: [ChordExtension] {
        ChordExtension.allCases.filter { $0.isAvailable(for: store.chordSettings.quality) }
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
        let validExtensions = store.chordSettings.extensions.filter { $0.isAvailable(for: store.chordSettings.quality) }
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

    private var customVisibleFretRange: ClosedRange<Int> {
        0...min(store.chordFretCount, 12)
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
            for fret in 0...activeFretCount {
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
            get: { max(store.chordStringCount, 6) },
            set: { newValue in
                noAnimation { setChordStringCount(max(newValue, 6)) }
            }
        )
    }

    private func customTuningDraftPitchBinding(storageIndex: Int) -> Binding<Int> {
        Binding(
            get: {
                guard customTuningDraftPitchClasses.indices.contains(storageIndex) else {
                    return defaultTuningPitchClasses(for: activeTuningStringCount)[storageIndex]
                }
                return customTuningDraftPitchClasses[storageIndex]
            },
            set: { newValue in
                noAnimation {
                    ensureCustomTuningDraftPitchCount()
                    guard customTuningDraftPitchClasses.indices.contains(storageIndex) else { return }
                    customTuningDraftPitchClasses[storageIndex] = newValue
                }
            }
        )
    }

    private func customTuningPitchName(storageIndex: Int) -> String {
        let fallback = defaultTuningPitchClasses(for: activeTuningStringCount)
        let pitch = customTuningDraftPitchClasses.indices.contains(storageIndex)
            ? customTuningDraftPitchClasses[storageIndex]
            : fallback[storageIndex]
        return customTuningNoteNames[pitch]
    }

    private func shiftCustomTuningPitch(storageIndex: Int, by semitones: Int) {
        ensureCustomTuningDraftPitchCount()
        guard customTuningDraftPitchClasses.indices.contains(storageIndex) else { return }
        customTuningDraftPitchClasses[storageIndex] = shiftedPitch(customTuningDraftPitchClasses[storageIndex], by: semitones)
    }

    private func shiftAllCustomTuningPitches(by semitones: Int) {
        ensureCustomTuningDraftPitchCount()
        customTuningDraftPitchClasses = customTuningDraftPitchClasses.map { shiftedPitch($0, by: semitones) }
    }

    private func shiftedPitch(_ pitch: Int, by semitones: Int) -> Int {
        (pitch + semitones + 120) % 12
    }

    private func dismissKeyboard() {
        isCustomTuningNameFocused = false
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
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
            }
        }
        updateSupportedOrientations(for: mode)
    }

    private func returnToModeSelection() {
        noAnimation {
            store.isCustomMode = false
            isCustomTuningSheetPresented = false
            isModeSelectionVisible = true
        }
        AppOrientationController.setSupportedOrientations(.allButUpsideDown)
    }

    private func compactHarmonyTitle(for mode: HarmonyMode) -> String {
        switch mode {
        case .functional: "Функц."
        case .modal: "Модальная"
        case .popular: "Популярные"
        case .saved: "Мои"
        }
    }

    private func harmonyModeIcon(for mode: HarmonyMode) -> String {
        switch mode {
        case .functional: "arrow.triangle.branch"
        case .modal: "circle.grid.2x2.fill"
        case .popular: "flame.fill"
        case .saved: "folder.fill"
        }
    }

    private func supportedOrientations(for mode: AppMode) -> UIInterfaceOrientationMask {
        mode == .modes ? .landscape : .allButUpsideDown
    }

    private func updateSupportedOrientations(for mode: AppMode) {
        AppOrientationController.setSupportedOrientations(supportedOrientations(for: mode))
    }

    private func compatibleTunings(for mode: AppMode) -> [TuningPreset] {
        tunings.filter { $0.stringCount == stringCount(for: mode) }
    }

    private func customTunings(for mode: AppMode) -> [CustomTuningPreset] {
        store.customTuningPresets.filter { $0.stringCount == stringCount(for: mode) }
    }

    private var customTuningsForTargetMode: [CustomTuningPreset] {
        store.customTuningPresets.filter { $0.stringCount == activeTuningStringCount }
    }

    private func selectedCustomTuning(for mode: AppMode) -> CustomTuningPreset? {
        let stringCount = stringCount(for: mode)
        let selectedID = mode == .chords ? store.chordSelectedCustomTuningID : store.selectedCustomTuningID
        guard let selectedID else { return nil }
        return store.customTuningPresets.first { $0.id == selectedID && $0.stringCount == stringCount }
    }

    private func selectedTuning(for mode: AppMode) -> TuningPreset {
        let stringCount = stringCount(for: mode)
        if let selectedCustomTuning = selectedCustomTuning(for: mode) {
            return TuningPreset.custom(
                id: customTuningMenuID(for: selectedCustomTuning.id),
                name: selectedCustomTuning.name,
                stringCount: stringCount,
                pitchClasses: selectedCustomTuning.pitchClasses,
                noteNames: noteNames(for: mode)
            )
        }
        let tuningID = mode == .chords ? store.chordSelectedTuningID : store.selectedTuningID
        let compatibleTunings = compatibleTunings(for: mode)
        return compatibleTunings.first { $0.id == tuningID } ?? compatibleTunings[0]
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
                    return customTuningMenuID(for: selectedCustomTuning.id)
                }
                return selectedTuning(for: mode).id
            },
            set: { newValue in
                noAnimation {
                    if newValue == manageCustomTuningID {
                        customTuningTargetMode = mode
                        prepareNewCustomTuningDraft()
                        isCustomTuningSheetPresented = true
                    } else if let customID = customTuningID(fromMenuID: newValue) {
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
        let tuningsForCount = tunings.filter { $0.stringCount == count }
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
        let tuningsForCount = tunings.filter { $0.stringCount == count }
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

    private func customTuningMenuID(for id: String) -> String {
        "custom:\(id)"
    }

    private func customTuningID(fromMenuID menuID: String) -> String? {
        guard menuID.hasPrefix("custom:") else { return nil }
        return String(menuID.dropFirst("custom:".count))
    }

    private func tuningSummary(for pitchClasses: [Int]) -> String {
        pitchClasses.reversed().map { customTuningNoteNames[$0] }.joined(separator: " ")
    }

    private func defaultTuningPitchClasses(for stringCount: Int) -> [Int] {
        let fallback = tunings.first { $0.stringCount == stringCount }?.strings.map(\.pitchClass) ?? Array(repeating: 0, count: stringCount)
        return fallback
    }

    private func ensureCustomTuningDraftPitchCount() {
        let fallback = defaultTuningPitchClasses(for: activeTuningStringCount)
        customTuningDraftPitchClasses = Array(customTuningDraftPitchClasses.prefix(activeTuningStringCount))
        while customTuningDraftPitchClasses.count < activeTuningStringCount {
            customTuningDraftPitchClasses.append(fallback[customTuningDraftPitchClasses.count])
        }
        customTuningDraftPitchClasses = customTuningDraftPitchClasses.map { min(max($0, 0), 11) }
    }

    private func prepareNewCustomTuningDraft() {
        editingCustomTuningID = nil
        customTuningDraftName = ""
        customTuningDraftPitchClasses = defaultTuningPitchClasses(for: activeTuningStringCount)
        ensureCustomTuningDraftPitchCount()
    }

    private func resetCustomTuningDraft() {
        prepareNewCustomTuningDraft()
    }

    private func editCustomTuning(_ preset: CustomTuningPreset) {
        editingCustomTuningID = preset.id
        customTuningDraftName = preset.name
        customTuningDraftPitchClasses = preset.pitchClasses
        ensureCustomTuningDraftPitchCount()
    }

    private func saveCustomTuningDraft() {
        let name = customTuningDraftName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        ensureCustomTuningDraftPitchCount()

        if let editingCustomTuningID,
           let index = store.customTuningPresets.firstIndex(where: { $0.id == editingCustomTuningID }) {
            var presets = store.customTuningPresets
            presets[index].name = name
            presets[index].stringCount = activeTuningStringCount
            presets[index].pitchClasses = customTuningDraftPitchClasses
            store.customTuningPresets = presets
            setSelectedCustomTuning(editingCustomTuningID, for: customTuningTargetMode)
        } else {
            let preset = CustomTuningPreset(
                name: name,
                stringCount: activeTuningStringCount,
                pitchClasses: customTuningDraftPitchClasses
            )
            store.customTuningPresets.append(preset)
            setSelectedCustomTuning(preset.id, for: customTuningTargetMode)
        }

        syncChordShape()
        prepareNewCustomTuningDraft()
        isCustomTuningNameFocused = true
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
        if editingCustomTuningID == preset.id {
            prepareNewCustomTuningDraft()
        }
        syncChordShape()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
