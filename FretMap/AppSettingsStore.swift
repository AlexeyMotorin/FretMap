import Foundation
import Combine

final class AppSettingsStore: ObservableObject {
    private static let storageKey = "neckFingering.appSettings.v1"
    private let defaults: UserDefaults
    private var isRestoring = false

    @Published var appMode: AppMode { didSet { save() } }
    @Published var rootNote: Int { didSet { save() } }
    @Published var selectedScaleID: String { didSet { save() } }
    @Published var stringCount: Int { didSet { save() } }
    @Published var selectedTuningID: String { didSet { save() } }
    @Published var isCustomTuningEnabled: Bool { didSet { save() } }
    @Published var customTuningPitchClasses: [Int: [Int]] { didSet { save() } }
    @Published var customTuningPresets: [CustomTuningPreset] { didSet { save() } }
    @Published var selectedCustomTuningID: String? { didSet { save() } }
    @Published var fretCount: Int { didSet { save() } }
    @Published var chordStringCount: Int { didSet { save() } }
    @Published var chordSelectedTuningID: String { didSet { save() } }
    @Published var chordIsCustomTuningEnabled: Bool { didSet { save() } }
    @Published var chordSelectedCustomTuningID: String? { didSet { save() } }
    @Published var chordFretCount: Int { didSet { save() } }
    @Published var chordAccidentalStyle: AccidentalStyle { didSet { save() } }
    @Published var chordShowsDegreeNumbers: Bool { didSet { save() } }
    @Published var chordHighlightsDegrees: Bool { didSet { save() } }
    @Published var areChordExtensionsVisible: Bool { didSet { save() } }
    @Published var accidentalStyle: AccidentalStyle { didSet { save() } }
    @Published var isSettingsVisible: Bool { didSet { save() } }
    @Published var chordSettings: ChordSettings { didSet { save() } }
    @Published var isCustomMode: Bool { didSet { save() } }
    @Published var customPositions: Set<FretPosition> { didSet { save() } }
    @Published var harmonyMode: HarmonyMode { didSet { save() } }
    @Published var popularScaleID: String { didSet { save() } }
    @Published var isModeSwitcherVisible: Bool { didSet { save() } }
    @Published var showsDegreeNumbers: Bool { didSet { save() } }
    @Published var highlightsScaleDegrees: Bool { didSet { save() } }
    @Published var showsScaleBoxes: Bool { didSet { save() } }

    @Published var functionalRoot: Int { didSet { save() } }
    @Published var functionalKeyMode: FunctionalKeyMode { didSet { save() } }
    @Published var functionalChordKind: FunctionalChordKind { didSet { save() } }
    @Published var functionalChordCount: Int { didSet { save() } }
    @Published var functionalSelectedDegrees: [Int] { didSet { save() } }
    @Published var functionalSelectedChordKinds: [FunctionalChordKind] { didSet { save() } }

    @Published var modalRoot: Int { didSet { save() } }
    @Published var modalMode: ModalBuilderMode { didSet { save() } }
    @Published var modalChordKind: FunctionalChordKind { didSet { save() } }
    @Published var modalChordCount: Int { didSet { save() } }
    @Published var modalSelectedDegrees: [Int] { didSet { save() } }
    @Published var modalSelectedChordKinds: [FunctionalChordKind] { didSet { save() } }
    @Published var popularGlobalRoot: Int { didSet { save() } }
    @Published var popularProgressionRoots: [String: Int] { didSet { save() } }
    @Published var popularSeventhChordIndexes: [String: [Int]] { didSet { save() } }
    @Published var popularSlashChordConfigurations: [String: [Int: PopularSlashChordConfiguration]] { didSet { save() } }
    @Published var popularRatings: [String: Int] { didSet { save() } }
    @Published var favoriteProgressionIDs: [String] { didSet { save() } }
    @Published var popularCollectionMode: PopularCollectionMode { didSet { save() } }
    @Published var popularSortMode: PopularSortMode { didSet { save() } }
    @Published var savedHarmonyProgressions: [SavedHarmonyProgression] { didSet { save() } }
    @Published var harmonyTempoBPM: Double { didSet { save() } }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let snapshot = Self.loadSnapshot(from: defaults) ?? .default
        isRestoring = true

        appMode = .modes
        rootNote = snapshot.rootNote
        selectedScaleID = snapshot.selectedScaleID
        stringCount = snapshot.stringCount
        selectedTuningID = snapshot.selectedTuningID
        isCustomTuningEnabled = snapshot.isCustomTuningEnabled ?? false
        customTuningPitchClasses = snapshot.customTuningPitchClasses ?? [:]
        customTuningPresets = snapshot.customTuningPresets ?? []
        selectedCustomTuningID = snapshot.selectedCustomTuningID
        fretCount = snapshot.fretCount
        chordStringCount = snapshot.chordStringCount ?? max(snapshot.stringCount, 6)
        chordSelectedTuningID = snapshot.chordSelectedTuningID ?? snapshot.selectedTuningID
        chordIsCustomTuningEnabled = snapshot.chordIsCustomTuningEnabled ?? (snapshot.isCustomTuningEnabled ?? false)
        chordSelectedCustomTuningID = snapshot.chordSelectedCustomTuningID ?? snapshot.selectedCustomTuningID
        chordFretCount = snapshot.chordFretCount ?? snapshot.fretCount
        chordAccidentalStyle = snapshot.chordAccidentalStyle ?? snapshot.accidentalStyle
        chordShowsDegreeNumbers = snapshot.chordShowsDegreeNumbers ?? snapshot.showsDegreeNumbers
        chordHighlightsDegrees = snapshot.chordHighlightsDegrees ?? false
        areChordExtensionsVisible = snapshot.areChordExtensionsVisible ?? true
        accidentalStyle = snapshot.accidentalStyle
        isSettingsVisible = true
        chordSettings = snapshot.chordSettings
        isCustomMode = false
        customPositions = Set(snapshot.customPositions)
        harmonyMode = snapshot.harmonyMode
        popularScaleID = snapshot.popularScaleID
        isModeSwitcherVisible = snapshot.isModeSwitcherVisible
        showsDegreeNumbers = snapshot.showsDegreeNumbers
        highlightsScaleDegrees = snapshot.highlightsScaleDegrees ?? false
        showsScaleBoxes = snapshot.showsScaleBoxes ?? false

        functionalRoot = snapshot.functionalRoot
        functionalKeyMode = snapshot.functionalKeyMode
        functionalChordKind = snapshot.functionalChordKind
        functionalChordCount = snapshot.functionalChordCount
        functionalSelectedDegrees = snapshot.functionalSelectedDegrees
        functionalSelectedChordKinds = snapshot.functionalSelectedChordKinds ?? Array(repeating: .triad, count: 8)

        modalRoot = snapshot.modalRoot
        modalMode = snapshot.modalMode
        modalChordKind = snapshot.modalChordKind
        modalChordCount = snapshot.modalChordCount
        modalSelectedDegrees = snapshot.modalSelectedDegrees
        modalSelectedChordKinds = snapshot.modalSelectedChordKinds ?? Array(repeating: .triad, count: 8)
        popularGlobalRoot = snapshot.popularGlobalRoot ?? -1
        popularProgressionRoots = snapshot.popularProgressionRoots
        popularSeventhChordIndexes = snapshot.popularSeventhChordIndexes ?? [:]
        popularSlashChordConfigurations = snapshot.popularSlashChordConfigurations ?? [:]
        popularRatings = snapshot.popularRatings ?? [:]
        favoriteProgressionIDs = snapshot.favoriteProgressionIDs ?? []
        popularCollectionMode = snapshot.popularCollectionMode ?? .popular
        popularSortMode = snapshot.popularSortMode ?? .defaultOrder
        savedHarmonyProgressions = snapshot.savedHarmonyProgressions ?? []
        harmonyTempoBPM = snapshot.harmonyTempoBPM ?? 120

        isRestoring = false
        normalize()
    }

    func normalize() {
        rootNote = clampedPitch(rootNote)
        chordSettings.root = clampedPitch(chordSettings.root)
        functionalRoot = clampedPitch(functionalRoot)
        modalRoot = clampedPitch(modalRoot)
        popularGlobalRoot = popularGlobalRoot == -1 ? -1 : clampedPitch(popularGlobalRoot)
        stringCount = min(max(stringCount, 4), 8)
        chordStringCount = min(max(chordStringCount, 6), 8)
        customTuningPitchClasses = normalizedCustomTunings(customTuningPitchClasses)
        migrateLegacyCustomTuningIfNeeded()
        customTuningPresets = normalizedCustomTuningPresets(customTuningPresets)
        fretCount = min(max(fretCount, 12), 24)
        chordFretCount = min(max(chordFretCount, 12), 24)
        functionalChordCount = functionalChordCount == 8 ? 8 : 4
        modalChordCount = modalChordCount == 8 ? 8 : 4
        functionalSelectedDegrees = normalizedDegrees(functionalSelectedDegrees, fallback: 1, allowed: Array(1...7))
        modalSelectedDegrees = normalizedDegrees(modalSelectedDegrees, fallback: 1, allowed: Array(1...7))
        functionalSelectedChordKinds = normalizedChordKinds(functionalSelectedChordKinds)
        modalSelectedChordKinds = normalizedChordKinds(modalSelectedChordKinds)
        popularRatings = popularRatings.mapValues { min(max($0, 1), 5) }
        favoriteProgressionIDs = Array(Set(favoriteProgressionIDs))
        harmonyTempoBPM = min(max(harmonyTempoBPM, 40), 200)
        savedHarmonyProgressions = savedHarmonyProgressions.map { progression in
            var normalized = progression
            normalized.root = progression.root == -1 ? -1 : clampedPitch(progression.root)
            normalized.degrees = Array(progression.degrees.prefix(8))
            normalized.chordKinds = Array(progression.chordKinds.prefix(normalized.degrees.count))
            while normalized.chordKinds.count < normalized.degrees.count {
                normalized.chordKinds.append(.triad)
            }
            normalized.rating = min(max(progression.rating, 1), 5)
            return normalized
        }

        if !ScalePattern.all.contains(where: { $0.id == selectedScaleID }) {
            selectedScaleID = ScalePattern.ionian.id
        }
        if !ScalePattern.all.contains(where: { $0.id == popularScaleID }) {
            popularScaleID = ScalePattern.ionian.id
        }
        if !TuningPreset.all.contains(where: { $0.id == selectedTuningID && $0.stringCount == stringCount }) {
            selectedTuningID = TuningPreset.all.first { $0.stringCount == stringCount }?.id ?? TuningPreset.standard6.id
        }
        if !TuningPreset.all.contains(where: { $0.id == chordSelectedTuningID && $0.stringCount == chordStringCount }) {
            chordSelectedTuningID = TuningPreset.all.first { $0.stringCount == chordStringCount }?.id ?? TuningPreset.standard6.id
        }
        if let selectedCustomTuningID, !customTuningPresets.contains(where: { $0.id == selectedCustomTuningID && $0.stringCount == stringCount }) {
            self.selectedCustomTuningID = nil
            isCustomTuningEnabled = false
        }
        if let chordSelectedCustomTuningID, !customTuningPresets.contains(where: { $0.id == chordSelectedCustomTuningID && $0.stringCount == chordStringCount }) {
            self.chordSelectedCustomTuningID = nil
            chordIsCustomTuningEnabled = false
        }
        if !ChordSize.available(for: chordSettings.quality).contains(chordSettings.size) {
            chordSettings.size = ChordSize.available(for: chordSettings.quality).first ?? .triad
        }
        save()
    }

    private func normalizedDegrees(_ degrees: [Int], fallback: Int, allowed: [Int]) -> [Int] {
        var result = Array(degrees.prefix(8))
        while result.count < 8 {
            result.append(fallback)
        }
        return result.map { allowed.contains($0) ? $0 : fallback }
    }

    private func clampedPitch(_ pitch: Int) -> Int {
        min(max(pitch, 0), 11)
    }

    private func save() {
        guard !isRestoring else { return }
        let snapshot = AppSettingsSnapshot(
            appMode: appMode,
            rootNote: rootNote,
            selectedScaleID: selectedScaleID,
            stringCount: stringCount,
            selectedTuningID: selectedTuningID,
            isCustomTuningEnabled: isCustomTuningEnabled,
            customTuningPitchClasses: customTuningPitchClasses,
            customTuningPresets: customTuningPresets,
            selectedCustomTuningID: selectedCustomTuningID,
            fretCount: fretCount,
            chordStringCount: chordStringCount,
            chordSelectedTuningID: chordSelectedTuningID,
            chordIsCustomTuningEnabled: chordIsCustomTuningEnabled,
            chordSelectedCustomTuningID: chordSelectedCustomTuningID,
            chordFretCount: chordFretCount,
            chordAccidentalStyle: chordAccidentalStyle,
            chordShowsDegreeNumbers: chordShowsDegreeNumbers,
            chordHighlightsDegrees: chordHighlightsDegrees,
            areChordExtensionsVisible: areChordExtensionsVisible,
            accidentalStyle: accidentalStyle,
            isSettingsVisible: isSettingsVisible,
            chordSettings: chordSettings,
            isCustomMode: isCustomMode,
            customPositions: Array(customPositions),
            harmonyMode: harmonyMode,
            popularScaleID: popularScaleID,
            isModeSwitcherVisible: isModeSwitcherVisible,
            showsDegreeNumbers: showsDegreeNumbers,
            highlightsScaleDegrees: highlightsScaleDegrees,
            showsScaleBoxes: showsScaleBoxes,
            functionalRoot: functionalRoot,
            functionalKeyMode: functionalKeyMode,
            functionalChordKind: functionalChordKind,
            functionalChordCount: functionalChordCount,
            functionalSelectedDegrees: functionalSelectedDegrees,
            functionalSelectedChordKinds: functionalSelectedChordKinds,
            modalRoot: modalRoot,
            modalMode: modalMode,
            modalChordKind: modalChordKind,
            modalChordCount: modalChordCount,
            modalSelectedDegrees: modalSelectedDegrees,
            modalSelectedChordKinds: modalSelectedChordKinds,
            popularGlobalRoot: popularGlobalRoot,
            popularProgressionRoots: popularProgressionRoots,
            popularSeventhChordIndexes: popularSeventhChordIndexes,
            popularSlashChordConfigurations: popularSlashChordConfigurations,
            popularRatings: popularRatings,
            favoriteProgressionIDs: favoriteProgressionIDs,
            popularCollectionMode: popularCollectionMode,
            popularSortMode: popularSortMode,
            savedHarmonyProgressions: savedHarmonyProgressions,
            harmonyTempoBPM: harmonyTempoBPM
        )
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        defaults.set(data, forKey: Self.storageKey)
    }

    private static func loadSnapshot(from defaults: UserDefaults) -> AppSettingsSnapshot? {
        guard let data = defaults.data(forKey: storageKey) else { return nil }
        return try? JSONDecoder().decode(AppSettingsSnapshot.self, from: data)
    }

    private func normalizedCustomTunings(_ tunings: [Int: [Int]]) -> [Int: [Int]] {
        var result = tunings
        for stringCount in 4...8 {
            let fallback = TuningPreset.all.first { $0.stringCount == stringCount }?.strings.map(\.pitchClass) ?? Array(repeating: 0, count: stringCount)
            var pitches = Array((result[stringCount] ?? fallback).prefix(stringCount))
            while pitches.count < stringCount {
                pitches.append(fallback[pitches.count])
            }
            result[stringCount] = pitches.map(clampedPitch)
        }
        return result
    }

    private func migrateLegacyCustomTuningIfNeeded() {
        guard customTuningPresets.isEmpty, isCustomTuningEnabled else { return }
        let pitches = customTuningPitchClasses[stringCount] ?? TuningPreset.all.first { $0.stringCount == stringCount }?.strings.map(\.pitchClass)
        guard let pitches else { return }
        let preset = CustomTuningPreset(name: "Кастомный", stringCount: stringCount, pitchClasses: pitches)
        customTuningPresets = [preset]
        selectedCustomTuningID = preset.id
    }

    private func normalizedCustomTuningPresets(_ presets: [CustomTuningPreset]) -> [CustomTuningPreset] {
        presets.compactMap { preset in
            let stringCount = min(max(preset.stringCount, 4), 8)
            let fallback = TuningPreset.all.first { $0.stringCount == stringCount }?.strings.map(\.pitchClass) ?? Array(repeating: 0, count: stringCount)
            var pitches = Array(preset.pitchClasses.prefix(stringCount))
            while pitches.count < stringCount {
                pitches.append(fallback[pitches.count])
            }
            let name = preset.name.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !name.isEmpty else { return nil }
            return CustomTuningPreset(
                id: preset.id,
                name: name,
                stringCount: stringCount,
                pitchClasses: pitches.map(clampedPitch)
            )
        }
    }

    private func normalizedChordKinds(_ kinds: [FunctionalChordKind]) -> [FunctionalChordKind] {
        var result = Array(kinds.prefix(8)).map { $0 == .mixed ? .triad : $0 }
        while result.count < 8 {
            result.append(.triad)
        }
        return result
    }
}

private struct AppSettingsSnapshot: Codable {
    var appMode: AppMode
    var rootNote: Int
    var selectedScaleID: String
    var stringCount: Int
    var selectedTuningID: String
    var isCustomTuningEnabled: Bool?
    var customTuningPitchClasses: [Int: [Int]]?
    var customTuningPresets: [CustomTuningPreset]?
    var selectedCustomTuningID: String?
    var fretCount: Int
    var chordStringCount: Int?
    var chordSelectedTuningID: String?
    var chordIsCustomTuningEnabled: Bool?
    var chordSelectedCustomTuningID: String?
    var chordFretCount: Int?
    var chordAccidentalStyle: AccidentalStyle?
    var chordShowsDegreeNumbers: Bool?
    var chordHighlightsDegrees: Bool?
    var areChordExtensionsVisible: Bool?
    var accidentalStyle: AccidentalStyle
    var isSettingsVisible: Bool
    var chordSettings: ChordSettings
    var isCustomMode: Bool
    var customPositions: [FretPosition]
    var harmonyMode: HarmonyMode
    var popularScaleID: String
    var isModeSwitcherVisible: Bool
    var showsDegreeNumbers: Bool
    var highlightsScaleDegrees: Bool?
    var showsScaleBoxes: Bool?
    var functionalRoot: Int
    var functionalKeyMode: FunctionalKeyMode
    var functionalChordKind: FunctionalChordKind
    var functionalChordCount: Int
    var functionalSelectedDegrees: [Int]
    var functionalSelectedChordKinds: [FunctionalChordKind]?
    var modalRoot: Int
    var modalMode: ModalBuilderMode
    var modalChordKind: FunctionalChordKind
    var modalChordCount: Int
    var modalSelectedDegrees: [Int]
    var modalSelectedChordKinds: [FunctionalChordKind]?
    var popularGlobalRoot: Int?
    var popularProgressionRoots: [String: Int]
    var popularSeventhChordIndexes: [String: [Int]]?
    var popularSlashChordConfigurations: [String: [Int: PopularSlashChordConfiguration]]?
    var popularRatings: [String: Int]?
    var favoriteProgressionIDs: [String]?
    var popularCollectionMode: PopularCollectionMode?
    var popularSortMode: PopularSortMode?
    var savedHarmonyProgressions: [SavedHarmonyProgression]?
    var harmonyTempoBPM: Double?

    static let `default` = AppSettingsSnapshot(
        appMode: .modes,
        rootNote: 0,
        selectedScaleID: ScalePattern.ionian.id,
        stringCount: 6,
        selectedTuningID: TuningPreset.standard6.id,
        isCustomTuningEnabled: false,
        customTuningPitchClasses: [:],
        customTuningPresets: [],
        selectedCustomTuningID: nil,
        fretCount: 24,
        chordStringCount: 6,
        chordSelectedTuningID: TuningPreset.standard6.id,
        chordIsCustomTuningEnabled: false,
        chordSelectedCustomTuningID: nil,
        chordFretCount: 24,
        chordAccidentalStyle: .flats,
        chordShowsDegreeNumbers: true,
        chordHighlightsDegrees: false,
        areChordExtensionsVisible: true,
        accidentalStyle: .flats,
        isSettingsVisible: true,
        chordSettings: ChordSettings(),
        isCustomMode: false,
        customPositions: [],
        harmonyMode: .functional,
        popularScaleID: ScalePattern.ionian.id,
        isModeSwitcherVisible: true,
        showsDegreeNumbers: true,
        highlightsScaleDegrees: false,
        showsScaleBoxes: false,
        functionalRoot: 0,
        functionalKeyMode: .major,
        functionalChordKind: .triad,
        functionalChordCount: 4,
        functionalSelectedDegrees: Array(repeating: 1, count: 8),
        functionalSelectedChordKinds: Array(repeating: .triad, count: 8),
        modalRoot: 0,
        modalMode: .dorian,
        modalChordKind: .triad,
        modalChordCount: 4,
        modalSelectedDegrees: Array(repeating: 1, count: 8),
        modalSelectedChordKinds: Array(repeating: .triad, count: 8),
        popularGlobalRoot: -1,
        popularProgressionRoots: [:],
        popularSeventhChordIndexes: [:],
        popularSlashChordConfigurations: [:],
        popularRatings: [:],
        favoriteProgressionIDs: [],
        popularCollectionMode: .popular,
        popularSortMode: .defaultOrder,
        savedHarmonyProgressions: [],
        harmonyTempoBPM: 120
    )
}
