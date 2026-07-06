import SwiftUI

enum AppMode: String, CaseIterable, Identifiable {
    case chords
    case modes
    case harmony

    var id: String { rawValue }

    var title: String {
        switch self {
        case .chords: "Аккорды"
        case .modes: "Лады"
        case .harmony: "Гармония"
        }
    }
}

enum HarmonyMode: String, CaseIterable, Identifiable {
    case functional
    case modal
    case popular

    var id: String { rawValue }

    var title: String {
        switch self {
        case .functional: "Функциональная"
        case .modal: "Модальная"
        case .popular: "Популярные"
        }
    }
}

enum AccidentalStyle: String, CaseIterable, Identifiable {
    case sharps
    case flats

    var id: String { rawValue }

    var title: String {
        switch self {
        case .sharps: "#"
        case .flats: "b"
        }
    }

    var noteNames: [String] {
        switch self {
        case .sharps:
            ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
        case .flats:
            ["C", "Db", "D", "Eb", "E", "F", "Gb", "G", "Ab", "A", "Bb", "B"]
        }
    }
}

struct GuitarString: Identifiable, Equatable {
    let id = UUID()
    let label: String
    let pitchClass: Int
}

struct TuningPreset: Identifiable, Equatable {
    let id: String
    let name: String
    let strings: [GuitarString]

    var stringCount: Int { strings.count }

    static let standard6 = TuningPreset(
        id: "standard-6",
        name: "Standard",
        strings: [
            GuitarString(label: "E", pitchClass: 4),
            GuitarString(label: "A", pitchClass: 9),
            GuitarString(label: "D", pitchClass: 2),
            GuitarString(label: "G", pitchClass: 7),
            GuitarString(label: "B", pitchClass: 11),
            GuitarString(label: "E", pitchClass: 4)
        ]
    )

    static let all: [TuningPreset] = [
        TuningPreset(id: "standard-4", name: "Bass Standard", strings: [
            GuitarString(label: "E", pitchClass: 4), GuitarString(label: "A", pitchClass: 9),
            GuitarString(label: "D", pitchClass: 2), GuitarString(label: "G", pitchClass: 7)
        ]),
        TuningPreset(id: "standard-5", name: "Bass 5", strings: [
            GuitarString(label: "B", pitchClass: 11), GuitarString(label: "E", pitchClass: 4),
            GuitarString(label: "A", pitchClass: 9), GuitarString(label: "D", pitchClass: 2),
            GuitarString(label: "G", pitchClass: 7)
        ]),
        .standard6,
        TuningPreset(id: "drop-d", name: "Drop D", strings: [
            GuitarString(label: "D", pitchClass: 2), GuitarString(label: "A", pitchClass: 9),
            GuitarString(label: "D", pitchClass: 2), GuitarString(label: "G", pitchClass: 7),
            GuitarString(label: "B", pitchClass: 11), GuitarString(label: "E", pitchClass: 4)
        ]),
        TuningPreset(id: "dadgad", name: "DADGAD", strings: [
            GuitarString(label: "D", pitchClass: 2), GuitarString(label: "A", pitchClass: 9),
            GuitarString(label: "D", pitchClass: 2), GuitarString(label: "G", pitchClass: 7),
            GuitarString(label: "A", pitchClass: 9), GuitarString(label: "D", pitchClass: 2)
        ]),
        TuningPreset(id: "open-g", name: "Open G", strings: [
            GuitarString(label: "D", pitchClass: 2), GuitarString(label: "G", pitchClass: 7),
            GuitarString(label: "D", pitchClass: 2), GuitarString(label: "G", pitchClass: 7),
            GuitarString(label: "B", pitchClass: 11), GuitarString(label: "D", pitchClass: 2)
        ]),
        TuningPreset(id: "standard-7", name: "7-string Standard", strings: [
            GuitarString(label: "B", pitchClass: 11), GuitarString(label: "E", pitchClass: 4),
            GuitarString(label: "A", pitchClass: 9), GuitarString(label: "D", pitchClass: 2),
            GuitarString(label: "G", pitchClass: 7), GuitarString(label: "B", pitchClass: 11),
            GuitarString(label: "E", pitchClass: 4)
        ]),
        TuningPreset(id: "drop-a", name: "Drop A", strings: [
            GuitarString(label: "A", pitchClass: 9), GuitarString(label: "E", pitchClass: 4),
            GuitarString(label: "A", pitchClass: 9), GuitarString(label: "D", pitchClass: 2),
            GuitarString(label: "G", pitchClass: 7), GuitarString(label: "B", pitchClass: 11),
            GuitarString(label: "E", pitchClass: 4)
        ]),
        TuningPreset(id: "standard-8", name: "8-string Standard", strings: [
            GuitarString(label: "F#", pitchClass: 6), GuitarString(label: "B", pitchClass: 11),
            GuitarString(label: "E", pitchClass: 4), GuitarString(label: "A", pitchClass: 9),
            GuitarString(label: "D", pitchClass: 2), GuitarString(label: "G", pitchClass: 7),
            GuitarString(label: "B", pitchClass: 11), GuitarString(label: "E", pitchClass: 4)
        ])
    ]
}

struct ScalePattern: Identifiable, Equatable {
    let id: String
    let name: String
    let shortName: String
    let intervals: [Int]
    let degreeNames: [String]

    func degreeLabel(for pitchClass: Int, root: Int) -> String? {
        let interval = (pitchClass - root + 12) % 12
        guard let index = intervals.firstIndex(of: interval), degreeNames.indices.contains(index) else {
            return nil
        }
        return degreeNames[index]
    }

    static let ionian = ScalePattern(
        id: "ionian",
        name: "Ионийский (Натуральный мажор)",
        shortName: "Ионийский",
        intervals: [0, 2, 4, 5, 7, 9, 11],
        degreeNames: ["1", "2", "3", "4", "5", "6", "7"]
    )
    static let dorian = ScalePattern(
        id: "dorian",
        name: "Дорийский (Минор с повышенной 6 ступенью)",
        shortName: "Дорийский",
        intervals: [0, 2, 3, 5, 7, 9, 10],
        degreeNames: ["1", "2", "b3", "4", "5", "6", "b7"]
    )
    static let phrygian = ScalePattern(
        id: "phrygian",
        name: "Фригийский (Минор с пониженной 2 ступенью)",
        shortName: "Фригийский",
        intervals: [0, 1, 3, 5, 7, 8, 10],
        degreeNames: ["1", "b2", "b3", "4", "5", "b6", "b7"]
    )
    static let lydian = ScalePattern(
        id: "lydian",
        name: "Лидийский (Мажор с повышенной 4 ступенью)",
        shortName: "Лидийский",
        intervals: [0, 2, 4, 6, 7, 9, 11],
        degreeNames: ["1", "2", "3", "#4", "5", "6", "7"]
    )
    static let mixolydian = ScalePattern(
        id: "mixolydian",
        name: "Миксолидийский (Мажор с пониженной 7 ступенью)",
        shortName: "Миксолидийский",
        intervals: [0, 2, 4, 5, 7, 9, 10],
        degreeNames: ["1", "2", "3", "4", "5", "6", "b7"]
    )
    static let aeolian = ScalePattern(
        id: "aeolian",
        name: "Эолийский (Натуральный минор)",
        shortName: "Эолийский",
        intervals: [0, 2, 3, 5, 7, 8, 10],
        degreeNames: ["1", "2", "b3", "4", "5", "b6", "b7"]
    )
    static let locrian = ScalePattern(
        id: "locrian",
        name: "Локрийский (Минор с пониженными 2 и 5 ступенями)",
        shortName: "Локрийский",
        intervals: [0, 1, 3, 5, 6, 8, 10],
        degreeNames: ["1", "b2", "b3", "4", "b5", "b6", "b7"]
    )
    static let majorPentatonic = ScalePattern(id: "major-penta", name: "Маж. пентатоника", shortName: "Маж. пентатоника", intervals: [0, 2, 4, 7, 9], degreeNames: ["1", "2", "3", "5", "6"])
    static let minorPentatonic = ScalePattern(id: "minor-penta", name: "Мин. пентатоника", shortName: "Мин. пентатоника", intervals: [0, 3, 5, 7, 10], degreeNames: ["1", "b3", "4", "5", "b7"])
    static let blues = ScalePattern(id: "blues", name: "Блюз", shortName: "Блюз", intervals: [0, 3, 5, 6, 7, 10], degreeNames: ["1", "b3", "4", "b5", "5", "b7"])
    static let chromatic = ScalePattern(id: "chromatic", name: "Хроматика", shortName: "Хроматика", intervals: Array(0...11), degreeNames: ["1", "b2", "2", "b3", "3", "4", "b5", "5", "b6", "6", "b7", "7"])

    static let all: [ScalePattern] = [
        .ionian, .dorian, .phrygian, .lydian, .mixolydian, .aeolian, .locrian,
        .majorPentatonic, .minorPentatonic, .blues, .chromatic
    ]
}

enum ChordQuality: String, CaseIterable, Identifiable {
    case major
    case minor
    case augmented
    case diminished

    var id: String { rawValue }

    var title: String {
        switch self {
        case .major: "Мажорный"
        case .minor: "Минорный"
        case .augmented: "Увеличенный"
        case .diminished: "Уменьшенный"
        }
    }

    var shortTitle: String {
        switch self {
        case .major: "maj"
        case .minor: "m"
        case .augmented: "aug"
        case .diminished: "dim"
        }
    }

    var triadIntervals: [Int] {
        switch self {
        case .major: [0, 4, 7]
        case .minor: [0, 3, 7]
        case .augmented: [0, 4, 8]
        case .diminished: [0, 3, 6]
        }
    }

    var triadDegrees: [String] {
        switch self {
        case .major: ["1", "3", "5"]
        case .minor: ["1", "b3", "5"]
        case .augmented: ["1", "3", "#5"]
        case .diminished: ["1", "b3", "b5"]
        }
    }

    var seventhInterval: Int {
        switch self {
        case .major: 11
        case .minor, .augmented, .diminished: 10
        }
    }
}

enum ChordSize: String, CaseIterable, Identifiable {
    case triad
    case majorSeventh
    case dominantSeventh
    case minorSeventh
    case halfDiminished

    var id: String { rawValue }

    var title: String {
        switch self {
        case .triad: "Трезвучие"
        case .majorSeventh: "maj7"
        case .dominantSeventh: "7"
        case .minorSeventh: "m7"
        case .halfDiminished: "m7b5"
        }
    }

    var intervals: [Int]? {
        switch self {
        case .triad: nil
        case .majorSeventh: [0, 4, 7, 11]
        case .dominantSeventh: [0, 4, 7, 10]
        case .minorSeventh: [0, 3, 7, 10]
        case .halfDiminished: [0, 3, 6, 10]
        }
    }

    var degreeNames: [String]? {
        switch self {
        case .triad: nil
        case .majorSeventh: ["1", "3", "5", "7"]
        case .dominantSeventh: ["1", "3", "5", "b7"]
        case .minorSeventh: ["1", "b3", "5", "b7"]
        case .halfDiminished: ["1", "b3", "b5", "b7"]
        }
    }

    static func available(for quality: ChordQuality) -> [ChordSize] {
        switch quality {
        case .major: [.triad, .majorSeventh, .dominantSeventh]
        case .minor: [.triad, .minorSeventh]
        case .diminished: [.triad, .halfDiminished]
        case .augmented: [.triad]
        }
    }
}

struct ChordTone {
    let interval: Int
    let degree: String
}

struct ChordSettings {
    var root: Int = 0
    var quality: ChordQuality = .major
    var size: ChordSize = .triad
    var startString: Int = 6
    var shapeID: String = "major-e"

    var tones: [ChordTone] {
        if let intervals = size.intervals, let degreeNames = size.degreeNames {
            return intervals.enumerated().map { index, interval in
                ChordTone(interval: interval, degree: degreeNames[index])
            }
        }

        return quality.triadIntervals.enumerated().map { index, interval in
            ChordTone(interval: interval, degree: quality.triadDegrees[index])
        }
    }

    var intervals: Set<Int> { Set(tones.map(\.interval)) }
}

struct ChordShape: Identifiable, Equatable {
    struct Note: Equatable {
        let stringNumber: Int
        let fret: Int
    }

    let id: String
    let title: String
    let quality: ChordQuality
    let size: ChordSize
    let rootString: Int
    let baseRoot: Int
    let notes: [Note]
    let barres: [ChordBarre]

    var menuTitle: String { "\(title) - от \(rootString) струны" }

    func transposedNotes(to root: Int) -> [Note] {
        let shift = transpositionShift(to: root)
        return notes.map { Note(stringNumber: $0.stringNumber, fret: $0.fret + shift) }
    }

    func transposedBarres(to root: Int) -> [ChordBarre] {
        let shift = transpositionShift(to: root)
        return barres.map { ChordBarre(fret: $0.fret + shift, fromStringNumber: $0.fromStringNumber, toStringNumber: $0.toStringNumber) }
    }

    private func transpositionShift(to root: Int) -> Int {
        let semitoneShift = (root - baseRoot + 12) % 12
        let shiftedFrets = notes.map { $0.fret + semitoneShift }
        if shiftedFrets.min() ?? 0 > 12 {
            return semitoneShift - 12
        }
        return semitoneShift
    }

    static let all: [ChordShape] = [
        ChordShape(id: "major-e", title: "E-shape баррэ", quality: .major, size: .triad, rootString: 6, baseRoot: 7, notes: [
            Note(stringNumber: 1, fret: 3), Note(stringNumber: 2, fret: 3), Note(stringNumber: 3, fret: 4),
            Note(stringNumber: 4, fret: 5), Note(stringNumber: 5, fret: 5), Note(stringNumber: 6, fret: 3)
        ], barres: [ChordBarre(fret: 3, fromStringNumber: 1, toStringNumber: 6)]),
        ChordShape(id: "major-d", title: "D-shape", quality: .major, size: .triad, rootString: 4, baseRoot: 7, notes: [
            Note(stringNumber: 1, fret: 7), Note(stringNumber: 2, fret: 8), Note(stringNumber: 3, fret: 7), Note(stringNumber: 4, fret: 5)
        ], barres: []),
        ChordShape(id: "major-c", title: "C-shape баррэ", quality: .major, size: .triad, rootString: 5, baseRoot: 7, notes: [
            Note(stringNumber: 1, fret: 7), Note(stringNumber: 2, fret: 8), Note(stringNumber: 3, fret: 7),
            Note(stringNumber: 4, fret: 9), Note(stringNumber: 5, fret: 10)
        ], barres: [ChordBarre(fret: 7, fromStringNumber: 1, toStringNumber: 3)]),
        ChordShape(id: "major-a", title: "A-shape баррэ", quality: .major, size: .triad, rootString: 5, baseRoot: 7, notes: [
            Note(stringNumber: 1, fret: 10), Note(stringNumber: 2, fret: 12), Note(stringNumber: 3, fret: 12),
            Note(stringNumber: 4, fret: 12), Note(stringNumber: 5, fret: 10)
        ], barres: [ChordBarre(fret: 10, fromStringNumber: 1, toStringNumber: 5)]),

        ChordShape(id: "minor-e", title: "E-shape баррэ", quality: .minor, size: .triad, rootString: 6, baseRoot: 7, notes: [
            Note(stringNumber: 1, fret: 3), Note(stringNumber: 2, fret: 3), Note(stringNumber: 3, fret: 3),
            Note(stringNumber: 4, fret: 5), Note(stringNumber: 5, fret: 5), Note(stringNumber: 6, fret: 3)
        ], barres: [ChordBarre(fret: 3, fromStringNumber: 1, toStringNumber: 6)]),
        ChordShape(id: "minor-d", title: "D-shape", quality: .minor, size: .triad, rootString: 4, baseRoot: 7, notes: [
            Note(stringNumber: 1, fret: 6), Note(stringNumber: 2, fret: 8), Note(stringNumber: 3, fret: 7), Note(stringNumber: 4, fret: 5)
        ], barres: []),
        ChordShape(id: "minor-a", title: "A-shape баррэ", quality: .minor, size: .triad, rootString: 5, baseRoot: 7, notes: [
            Note(stringNumber: 1, fret: 10), Note(stringNumber: 2, fret: 11), Note(stringNumber: 3, fret: 12),
            Note(stringNumber: 4, fret: 12), Note(stringNumber: 5, fret: 10)
        ], barres: [ChordBarre(fret: 10, fromStringNumber: 1, toStringNumber: 5)]),

        ChordShape(id: "dim-six", title: "Dim от 6 струны", quality: .diminished, size: .triad, rootString: 6, baseRoot: 7, notes: [
            Note(stringNumber: 3, fret: 3), Note(stringNumber: 4, fret: 5), Note(stringNumber: 5, fret: 4), Note(stringNumber: 6, fret: 3)
        ], barres: [ChordBarre(fret: 3, fromStringNumber: 3, toStringNumber: 6)]),
        ChordShape(id: "dim-four", title: "Dim от 4 струны", quality: .diminished, size: .triad, rootString: 4, baseRoot: 7, notes: [
            Note(stringNumber: 1, fret: 6), Note(stringNumber: 2, fret: 5), Note(stringNumber: 3, fret: 6), Note(stringNumber: 4, fret: 5)
        ], barres: []),
        ChordShape(id: "dim-five", title: "Dim от 5 струны", quality: .diminished, size: .triad, rootString: 5, baseRoot: 7, notes: [
            Note(stringNumber: 2, fret: 11), Note(stringNumber: 3, fret: 12), Note(stringNumber: 4, fret: 11), Note(stringNumber: 5, fret: 10)
        ], barres: []),

        ChordShape(id: "maj7-six", title: "maj7", quality: .major, size: .majorSeventh, rootString: 6, baseRoot: 7, notes: [
            Note(stringNumber: 2, fret: 3), Note(stringNumber: 3, fret: 4), Note(stringNumber: 4, fret: 4), Note(stringNumber: 6, fret: 3)
        ], barres: []),
        ChordShape(id: "maj7-five", title: "maj7", quality: .major, size: .majorSeventh, rootString: 5, baseRoot: 7, notes: [
            Note(stringNumber: 2, fret: 12), Note(stringNumber: 3, fret: 11), Note(stringNumber: 4, fret: 12), Note(stringNumber: 5, fret: 10)
        ], barres: []),
        ChordShape(id: "maj7-four", title: "maj7", quality: .major, size: .majorSeventh, rootString: 4, baseRoot: 7, notes: [
            Note(stringNumber: 1, fret: 2), Note(stringNumber: 2, fret: 3), Note(stringNumber: 3, fret: 4), Note(stringNumber: 4, fret: 5)
        ], barres: []),

        ChordShape(id: "dom7-six", title: "7 баррэ", quality: .major, size: .dominantSeventh, rootString: 6, baseRoot: 7, notes: [
            Note(stringNumber: 1, fret: 3), Note(stringNumber: 2, fret: 3), Note(stringNumber: 3, fret: 4),
            Note(stringNumber: 4, fret: 3), Note(stringNumber: 5, fret: 5), Note(stringNumber: 6, fret: 3)
        ], barres: [ChordBarre(fret: 3, fromStringNumber: 1, toStringNumber: 6)]),
        ChordShape(id: "dom7-five", title: "7", quality: .major, size: .dominantSeventh, rootString: 5, baseRoot: 7, notes: [
            Note(stringNumber: 2, fret: 8), Note(stringNumber: 3, fret: 10), Note(stringNumber: 4, fret: 9), Note(stringNumber: 5, fret: 10)
        ], barres: []),
        ChordShape(id: "dom7-four", title: "7", quality: .major, size: .dominantSeventh, rootString: 4, baseRoot: 7, notes: [
            Note(stringNumber: 1, fret: 7), Note(stringNumber: 2, fret: 6), Note(stringNumber: 3, fret: 7), Note(stringNumber: 4, fret: 5)
        ], barres: []),

        ChordShape(id: "m7-six", title: "m7 баррэ", quality: .minor, size: .minorSeventh, rootString: 6, baseRoot: 7, notes: [
            Note(stringNumber: 1, fret: 3), Note(stringNumber: 2, fret: 3), Note(stringNumber: 3, fret: 3),
            Note(stringNumber: 4, fret: 3), Note(stringNumber: 5, fret: 5), Note(stringNumber: 6, fret: 3)
        ], barres: [ChordBarre(fret: 3, fromStringNumber: 1, toStringNumber: 6)]),
        ChordShape(id: "m7-five", title: "m7", quality: .minor, size: .minorSeventh, rootString: 5, baseRoot: 7, notes: [
            Note(stringNumber: 1, fret: 10), Note(stringNumber: 2, fret: 11), Note(stringNumber: 3, fret: 10),
            Note(stringNumber: 4, fret: 12), Note(stringNumber: 5, fret: 10)
        ], barres: []),
        ChordShape(id: "m7-four", title: "m7", quality: .minor, size: .minorSeventh, rootString: 4, baseRoot: 7, notes: [
            Note(stringNumber: 1, fret: 6), Note(stringNumber: 2, fret: 6), Note(stringNumber: 3, fret: 7), Note(stringNumber: 4, fret: 5)
        ], barres: []),

        ChordShape(id: "m7b5-six", title: "m7b5", quality: .diminished, size: .halfDiminished, rootString: 6, baseRoot: 7, notes: [
            Note(stringNumber: 2, fret: 2), Note(stringNumber: 3, fret: 3), Note(stringNumber: 4, fret: 3), Note(stringNumber: 6, fret: 3)
        ], barres: []),
        ChordShape(id: "m7b5-five", title: "m7b5", quality: .diminished, size: .halfDiminished, rootString: 5, baseRoot: 7, notes: [
            Note(stringNumber: 2, fret: 11), Note(stringNumber: 3, fret: 10), Note(stringNumber: 4, fret: 11), Note(stringNumber: 5, fret: 10)
        ], barres: []),
        ChordShape(id: "m7b5-four", title: "m7b5", quality: .diminished, size: .halfDiminished, rootString: 4, baseRoot: 7, notes: [
            Note(stringNumber: 1, fret: 6), Note(stringNumber: 2, fret: 6), Note(stringNumber: 3, fret: 6), Note(stringNumber: 4, fret: 5)
        ], barres: [])
    ]
}

struct FretPosition: Hashable, Identifiable {
    let stringIndex: Int
    let fret: Int
    var id: String { "\(stringIndex)-\(fret)" }
}

struct FretMarker: Identifiable {
    let position: FretPosition
    let label: String
    let isRoot: Bool

    var id: FretPosition { position }
}

struct ChordBarre: Identifiable, Equatable {
    let fret: Int
    let fromStringNumber: Int
    let toStringNumber: Int

    var id: String { "\(fret)-\(fromStringNumber)-\(toStringNumber)" }
}

enum HarmonyColor: String {
    case green
    case yellow
    case red
    case blue
    case neutral

    var color: Color {
        switch self {
        case .green: Color(red: 0.20, green: 0.72, blue: 0.42)
        case .yellow: Color(red: 0.94, green: 0.75, blue: 0.22)
        case .red: Color(red: 0.86, green: 0.24, blue: 0.22)
        case .blue: Color(red: 0.25, green: 0.47, blue: 0.95)
        case .neutral: AppColors.mutedText
        }
    }
}

struct FunctionalHarmonyGroup: Identifiable {
    let id = UUID()
    let title: String
    let symbol: String
    let degrees: [(String, HarmonyColor)]
}

struct ModalHarmonyRow: Identifiable {
    let id = UUID()
    let title: String
    let cells: [(degree: String, chord: String, color: HarmonyColor)]
}

struct PopularProgression: Identifiable {
    let id: String
    let title: String
    let category: String
    let degrees: [String]
    let examples: [String]
    let popularity: Int
    let color: HarmonyColor

    var progressionText: String { degrees.joined(separator: " - ") }
}

enum HarmonyData {
    static let functional: [FunctionalHarmonyGroup] = [
        FunctionalHarmonyGroup(title: "Тоническая функция", symbol: "T", degrees: [("I", .green), ("III", .red), ("VI", .yellow)]),
        FunctionalHarmonyGroup(title: "Субдоминантовая функция", symbol: "S", degrees: [("II", .yellow), ("IV", .green), ("VII", .red)]),
        FunctionalHarmonyGroup(title: "Доминантная функция", symbol: "D", degrees: [("V", .green), ("VII", .yellow)])
    ]

    static let modalRows: [ModalHarmonyRow] = [
        ModalHarmonyRow(title: "Ионийский maj", cells: [("I", "maj", .neutral), ("ii", "m", .neutral), ("iii", "m", .neutral), ("IV", "maj", .neutral), ("V", "maj", .neutral), ("vi", "m", .neutral), ("vii°", "dim", .neutral)]),
        ModalHarmonyRow(title: "Эолийский min", cells: [("i", "m", .green), ("ii°", "dim", .red), ("III", "maj", .yellow), ("iv", "m", .green), ("v", "m", .red), ("VI", "maj", .yellow), ("VII", "maj", .red)]),
        ModalHarmonyRow(title: "Дорийский min #6", cells: [("i", "m", .green), ("ii", "m", .green), ("III", "maj", .yellow), ("IV", "maj", .green), ("v", "m", .red), ("vi°", "dim", .red), ("VII", "maj", .red)]),
        ModalHarmonyRow(title: "Фригийский min b2", cells: [("i", "m", .green), ("II", "maj", .green), ("III", "maj", .yellow), ("iv", "m", .red), ("V°", "dim", .red), ("VI", "maj", .yellow), ("vii", "m", .green)]),
        ModalHarmonyRow(title: "Лидийский maj #4", cells: [("I", "maj", .green), ("II", "maj", .green), ("iii", "m", .yellow), ("iv°", "dim", .red), ("V", "maj", .red), ("vi", "m", .yellow), ("vii", "m", .green)]),
        ModalHarmonyRow(title: "Миксолидийский maj b7", cells: [("I", "maj", .green), ("ii", "m", .yellow), ("iii°", "dim", .red), ("IV", "maj", .red), ("v", "m", .green), ("vi", "m", .yellow), ("VII", "maj", .green)]),
        ModalHarmonyRow(title: "Локрийский dim (min b2 b5)", cells: [("i°", "dim", .red), ("II", "maj", .yellow), ("iii", "m", .green), ("iv", "m", .green), ("V", "maj", .red), ("VI", "maj", .yellow), ("vi", "m", .green)])
    ]

    static func popularProgressions(for scale: ScalePattern) -> [PopularProgression] {
        let progressionsByScale: [String: [PopularProgression]] = [
            "ionian": [
                progression("ionian-pop-axis", "Поп-ось", "Beginner", ["I", "V", "vi", "IV"], ["In The Stars", "Right Now", "Praise"], 5, .green),
                progression("ionian-pachelbel", "Канонная цепочка", "Beginner", ["I", "V", "vi", "iii", "IV", "I", "IV", "V"], ["Go West", "Good Old Fashioned Lover Boy"], 5, .yellow),
                progression("ionian-doo-wop", "Magic changes", "Beginner", ["I", "vi", "IV", "V"], ["Baby", "Dream A Little Dream"], 4, .blue),
                progression("ionian-step-down", "Бас вниз", "Intermediate", ["I", "V/7", "vi", "I/5", "IV"], ["Stuttering", "Sunshine Laserbeams"], 4, .green),
                progression("ionian-secondary", "V/vi в обороте", "Intermediate", ["I", "V/vi", "vi", "IV", "V"], ["Absolute Beginners", "Pink In The Night"], 3, .red),
                progression("ionian-borrowed-vii", "Каденция через bVII", "Advanced", ["I", "bVII", "IV", "I"], ["redesign your logo", "A Stranger I Remain"], 3, .yellow)
            ],
            "dorian": [
                progression("dorian-vamp", "Дорийский вамп", "Modal", ["i", "IV", "i", "IV"], ["So What", "Oye Como Va"], 5, .green),
                progression("dorian-backdoor", "i - VII - IV", "Modal", ["i", "VII", "IV", "i"], ["Mad World", "Scarborough Fair"], 4, .blue),
                progression("dorian-two-four", "Минорная опора II-IV", "Modal", ["i", "ii", "IV", "i"], ["Drunken Sailor"], 3, .yellow),
                progression("dorian-five-minor", "С мягкой доминантой", "Modal", ["i", "v", "IV", "i"], ["Riders on the Storm"], 3, .red)
            ],
            "phrygian": [
                progression("phrygian-half-step", "Фригийский полутон", "Modal", ["i", "II", "i", "VII"], ["Wherever I May Roam"], 5, .red),
                progression("phrygian-spanish", "Испанский оборот", "Modal", ["i", "VII", "VI", "V"], ["Malaguena"], 4, .yellow),
                progression("phrygian-bii", "bII как центр тяжести", "Modal", ["i", "II", "VII", "i"], ["Set the Controls"], 4, .green),
                progression("phrygian-dark", "Темная каденция", "Modal", ["i", "iv", "II", "i"], ["War Pigs"], 3, .blue)
            ],
            "lydian": [
                progression("lydian-two", "Лидийская II ступень", "Modal", ["I", "II", "I", "V"], ["Flying in a Blue Dream"], 5, .green),
                progression("lydian-sharp-four", "#iv° как краска", "Modal", ["I", "#iv°", "V", "I"], ["The Simpsons Theme"], 4, .yellow),
                progression("lydian-lift", "Подъем через II", "Modal", ["I", "II", "iii", "I"], ["Dreams"], 3, .blue),
                progression("lydian-wide", "Широкая мажорная петля", "Modal", ["I", "V", "II", "I"], ["Man on the Moon"], 3, .green)
            ],
            "mixolydian": [
                progression("mixolydian-rock", "Рок-каденция bVII-IV", "Modal", ["I", "VII", "IV", "I"], ["Sweet Home Alabama", "Hey Jude"], 5, .green),
                progression("mixolydian-v-minor", "Минорная v", "Modal", ["I", "v", "VII", "IV"], ["Norwegian Wood"], 4, .blue),
                progression("mixolydian-plagal", "Плагальная петля", "Modal", ["I", "IV", "VII", "I"], ["Fire on the Mountain"], 4, .yellow),
                progression("mixolydian-cadence", "Возврат через bVII", "Modal", ["I", "VII", "I", "V"], ["Sympathy for the Devil"], 3, .red)
            ],
            "aeolian": [
                progression("aeolian-pop-minor", "Минорная поп-ось", "Minor", ["i", "VI", "III", "VII"], ["Numb", "The Hanging Tree"], 5, .green),
                progression("aeolian-falling", "Нисходящая цепочка", "Minor", ["i", "VII", "VI", "VII"], ["All Along the Watchtower"], 5, .yellow),
                progression("aeolian-subdominant", "Минорная субдоминанта", "Minor", ["i", "iv", "VII", "i"], ["Losing My Religion"], 4, .blue),
                progression("aeolian-cinematic", "Кинематографичный минор", "Minor", ["i", "VI", "iv", "V"], ["House of the Rising Sun"], 3, .red)
            ],
            "locrian": [
                progression("locrian-bii", "Опора на bII", "Modal", ["i°", "II", "i°", "iv"], ["Army of Me"], 3, .red),
                progression("locrian-six", "Через bVI", "Modal", ["i°", "VI", "II", "i°"], ["Dust to Dust"], 2, .yellow),
                progression("locrian-four", "Полууменьшенная петля", "Modal", ["i°", "iv", "II", "i°"], ["YYZ"], 2, .blue),
                progression("locrian-release", "С выходом в bVII", "Modal", ["i°", "VII", "II", "i°"], ["Juicebox"], 2, .green)
            ]
        ]

        return progressionsByScale[scale.id] ?? progressionsByScale["ionian"] ?? []
    }

    private static func progression(
        _ id: String,
        _ title: String,
        _ category: String,
        _ degrees: [String],
        _ examples: [String],
        _ popularity: Int,
        _ color: HarmonyColor
    ) -> PopularProgression {
        PopularProgression(
            id: id,
            title: title,
            category: category,
            degrees: degrees,
            examples: examples,
            popularity: popularity,
            color: color
        )
    }
}

enum ChordIdentifier {
    static func identify(pitchClasses: Set<Int>, noteNames: [String]) -> String? {
        guard pitchClasses.count >= 3 else { return nil }

        let qualities: [(String, [Int])] = [
            ("maj", [0, 4, 7]),
            ("m", [0, 3, 7]),
            ("aug", [0, 4, 8]),
            ("dim", [0, 3, 6]),
            ("maj7", [0, 4, 7, 11]),
            ("7", [0, 4, 7, 10]),
            ("m7", [0, 3, 7, 10]),
            ("m7b5", [0, 3, 6, 10]),
            ("dim7", [0, 3, 6, 9])
        ]

        for root in 0..<12 {
            let intervals = Set(pitchClasses.map { ($0 - root + 12) % 12 })
            for quality in qualities where Set(quality.1).isSubset(of: intervals) {
                return "\(noteNames[root]) \(quality.0)"
            }
        }

        return nil
    }
}

enum AppColors {
    static let page = Color(red: 0.08, green: 0.09, blue: 0.12)
    static let panel = Color(red: 0.12, green: 0.13, blue: 0.18)
    static let control = Color(red: 0.24, green: 0.28, blue: 0.38)
    static let fretboard = Color(red: 0.15, green: 0.19, blue: 0.23)
    static let nut = Color(red: 0.47, green: 0.54, blue: 0.64)
    static let string = Color(red: 0.68, green: 0.76, blue: 0.86)
    static let stringGlow = Color(red: 0.72, green: 0.84, blue: 1.0)
    static let inlay = Color(red: 0.65, green: 0.72, blue: 0.76)
    static let noteMarker = Color.white
    static let barre = Color(red: 0.13, green: 0.74, blue: 0.46)
    static let rootText = Color(red: 0.18, green: 0.48, blue: 0.86)
    static let noteText = Color(red: 0.07, green: 0.08, blue: 0.09)
    static let openStringStroke = Color(red: 0.92, green: 0.67, blue: 0.22)
    static let primaryText = Color.white.opacity(0.92)
    static let mutedText = Color(red: 0.72, green: 0.77, blue: 0.84)
}
