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
    @Published var fretCount: Int { didSet { save() } }
    @Published var accidentalStyle: AccidentalStyle { didSet { save() } }
    @Published var isSettingsVisible: Bool { didSet { save() } }
    @Published var chordSettings: ChordSettings { didSet { save() } }
    @Published var isCustomMode: Bool { didSet { save() } }
    @Published var customPositions: Set<FretPosition> { didSet { save() } }
    @Published var harmonyMode: HarmonyMode { didSet { save() } }
    @Published var popularScaleID: String { didSet { save() } }
    @Published var isModeSwitcherVisible: Bool { didSet { save() } }
    @Published var showsDegreeNumbers: Bool { didSet { save() } }

    @Published var functionalRoot: Int { didSet { save() } }
    @Published var functionalKeyMode: FunctionalKeyMode { didSet { save() } }
    @Published var functionalChordKind: FunctionalChordKind { didSet { save() } }
    @Published var functionalChordCount: Int { didSet { save() } }
    @Published var functionalSelectedDegrees: [Int] { didSet { save() } }

    @Published var modalRoot: Int { didSet { save() } }
    @Published var modalMode: ModalBuilderMode { didSet { save() } }
    @Published var modalChordKind: FunctionalChordKind { didSet { save() } }
    @Published var modalChordCount: Int { didSet { save() } }
    @Published var modalSelectedDegrees: [Int] { didSet { save() } }
    @Published var popularProgressionRoots: [String: Int] { didSet { save() } }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let snapshot = Self.loadSnapshot(from: defaults) ?? .default
        isRestoring = true

        appMode = snapshot.appMode
        rootNote = snapshot.rootNote
        selectedScaleID = snapshot.selectedScaleID
        stringCount = snapshot.stringCount
        selectedTuningID = snapshot.selectedTuningID
        fretCount = snapshot.fretCount
        accidentalStyle = snapshot.accidentalStyle
        isSettingsVisible = snapshot.isSettingsVisible
        chordSettings = snapshot.chordSettings
        isCustomMode = snapshot.isCustomMode
        customPositions = Set(snapshot.customPositions)
        harmonyMode = snapshot.harmonyMode
        popularScaleID = snapshot.popularScaleID
        isModeSwitcherVisible = snapshot.isModeSwitcherVisible
        showsDegreeNumbers = snapshot.showsDegreeNumbers

        functionalRoot = snapshot.functionalRoot
        functionalKeyMode = snapshot.functionalKeyMode
        functionalChordKind = snapshot.functionalChordKind
        functionalChordCount = snapshot.functionalChordCount
        functionalSelectedDegrees = snapshot.functionalSelectedDegrees

        modalRoot = snapshot.modalRoot
        modalMode = snapshot.modalMode
        modalChordKind = snapshot.modalChordKind
        modalChordCount = snapshot.modalChordCount
        modalSelectedDegrees = snapshot.modalSelectedDegrees
        popularProgressionRoots = snapshot.popularProgressionRoots

        isRestoring = false
        normalize()
    }

    func normalize() {
        rootNote = clampedPitch(rootNote)
        chordSettings.root = clampedPitch(chordSettings.root)
        functionalRoot = clampedPitch(functionalRoot)
        modalRoot = clampedPitch(modalRoot)
        stringCount = min(max(stringCount, 4), 8)
        fretCount = min(max(fretCount, 12), 24)
        functionalChordCount = functionalChordCount == 8 ? 8 : 4
        modalChordCount = modalChordCount == 8 ? 8 : 4
        functionalSelectedDegrees = normalizedDegrees(functionalSelectedDegrees, fallback: 1, allowed: Array(1...7))
        modalSelectedDegrees = normalizedDegrees(modalSelectedDegrees, fallback: modalMode.availableDegrees[0], allowed: modalMode.availableDegrees)

        if !ScalePattern.all.contains(where: { $0.id == selectedScaleID }) {
            selectedScaleID = ScalePattern.ionian.id
        }
        if !ScalePattern.all.contains(where: { $0.id == popularScaleID }) {
            popularScaleID = ScalePattern.ionian.id
        }
        if !TuningPreset.all.contains(where: { $0.id == selectedTuningID && $0.stringCount == stringCount }) {
            selectedTuningID = TuningPreset.all.first { $0.stringCount == stringCount }?.id ?? TuningPreset.standard6.id
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
            fretCount: fretCount,
            accidentalStyle: accidentalStyle,
            isSettingsVisible: isSettingsVisible,
            chordSettings: chordSettings,
            isCustomMode: isCustomMode,
            customPositions: Array(customPositions),
            harmonyMode: harmonyMode,
            popularScaleID: popularScaleID,
            isModeSwitcherVisible: isModeSwitcherVisible,
            showsDegreeNumbers: showsDegreeNumbers,
            functionalRoot: functionalRoot,
            functionalKeyMode: functionalKeyMode,
            functionalChordKind: functionalChordKind,
            functionalChordCount: functionalChordCount,
            functionalSelectedDegrees: functionalSelectedDegrees,
            modalRoot: modalRoot,
            modalMode: modalMode,
            modalChordKind: modalChordKind,
            modalChordCount: modalChordCount,
            modalSelectedDegrees: modalSelectedDegrees,
            popularProgressionRoots: popularProgressionRoots
        )
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        defaults.set(data, forKey: Self.storageKey)
    }

    private static func loadSnapshot(from defaults: UserDefaults) -> AppSettingsSnapshot? {
        guard let data = defaults.data(forKey: storageKey) else { return nil }
        return try? JSONDecoder().decode(AppSettingsSnapshot.self, from: data)
    }
}

private struct AppSettingsSnapshot: Codable {
    var appMode: AppMode
    var rootNote: Int
    var selectedScaleID: String
    var stringCount: Int
    var selectedTuningID: String
    var fretCount: Int
    var accidentalStyle: AccidentalStyle
    var isSettingsVisible: Bool
    var chordSettings: ChordSettings
    var isCustomMode: Bool
    var customPositions: [FretPosition]
    var harmonyMode: HarmonyMode
    var popularScaleID: String
    var isModeSwitcherVisible: Bool
    var showsDegreeNumbers: Bool
    var functionalRoot: Int
    var functionalKeyMode: FunctionalKeyMode
    var functionalChordKind: FunctionalChordKind
    var functionalChordCount: Int
    var functionalSelectedDegrees: [Int]
    var modalRoot: Int
    var modalMode: ModalBuilderMode
    var modalChordKind: FunctionalChordKind
    var modalChordCount: Int
    var modalSelectedDegrees: [Int]
    var popularProgressionRoots: [String: Int]

    static let `default` = AppSettingsSnapshot(
        appMode: .modes,
        rootNote: 0,
        selectedScaleID: ScalePattern.ionian.id,
        stringCount: 6,
        selectedTuningID: TuningPreset.standard6.id,
        fretCount: 24,
        accidentalStyle: .flats,
        isSettingsVisible: true,
        chordSettings: ChordSettings(),
        isCustomMode: false,
        customPositions: [],
        harmonyMode: .functional,
        popularScaleID: ScalePattern.ionian.id,
        isModeSwitcherVisible: true,
        showsDegreeNumbers: true,
        functionalRoot: 0,
        functionalKeyMode: .major,
        functionalChordKind: .triad,
        functionalChordCount: 4,
        functionalSelectedDegrees: Array(repeating: 1, count: 8),
        modalRoot: 0,
        modalMode: .dorian,
        modalChordKind: .triad,
        modalChordCount: 4,
        modalSelectedDegrees: Array(repeating: 1, count: 8),
        popularProgressionRoots: [:]
    )
}
