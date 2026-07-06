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
        case .popular: "Самые популярные"
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

    var seventhInterval: Int {
        switch self {
        case .major: 11
        case .minor, .augmented, .diminished: 10
        }
    }
}

enum ChordSize: String, CaseIterable, Identifiable {
    case triad
    case seventh

    var id: String { rawValue }
    var title: String { self == .triad ? "Трезвучие" : "Септаккорд" }
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

    var tones: [ChordTone] {
        var result = quality.triadIntervals.enumerated().map { index, interval in
            ChordTone(interval: interval, degree: ["1", "3", "5"][index])
        }
        if size == .seventh {
            result.append(ChordTone(interval: quality.seventhInterval, degree: "7"))
        }
        return result
    }

    var intervals: Set<Int> { Set(tones.map(\.interval)) }
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

enum HarmonyData {
    static let functional: [FunctionalHarmonyGroup] = [
        FunctionalHarmonyGroup(title: "Тоническая функция", symbol: "T", degrees: [("I", .green), ("III", .red), ("VI", .yellow)]),
        FunctionalHarmonyGroup(title: "Субдоминантовая функция", symbol: "S", degrees: [("II", .yellow), ("IV", .green), ("VII", .red)]),
        FunctionalHarmonyGroup(title: "Доминантная функция", symbol: "D", degrees: [("V", .green), ("VII", .yellow)])
    ]

    static let modalRows: [ModalHarmonyRow] = [
        ModalHarmonyRow(title: "Ионийский maj", cells: [("I", "maj", .neutral), ("ii", "m", .neutral), ("iii", "m", .neutral), ("IV", "maj", .neutral), ("V", "maj", .neutral), ("vi", "m", .neutral), ("vii°", "dim", .neutral)]),
        ModalHarmonyRow(title: "Дорийский min #6", cells: [("i", "m", .green), ("ii", "m", .green), ("III", "maj", .yellow), ("IV", "maj", .green), ("v", "m", .red), ("vi°", "dim", .red), ("VII", "maj", .red)]),
        ModalHarmonyRow(title: "Фригийский min b2", cells: [("i", "m", .green), ("II", "maj", .green), ("III", "maj", .yellow), ("iv", "m", .red), ("V°", "dim", .red), ("VI", "maj", .yellow), ("vii", "m", .green)]),
        ModalHarmonyRow(title: "Лидийский maj #4", cells: [("I", "maj", .green), ("II", "maj", .green), ("iii", "m", .yellow), ("iv°", "dim", .red), ("V", "maj", .red), ("vi", "m", .yellow), ("vii", "m", .green)]),
        ModalHarmonyRow(title: "Миксолидийский maj b7", cells: [("I", "maj", .green), ("ii", "m", .yellow), ("iii°", "dim", .red), ("IV", "maj", .red), ("v", "m", .green), ("vi", "m", .yellow), ("VII", "maj", .green)]),
        ModalHarmonyRow(title: "Эолийский min", cells: [("i", "m", .green), ("ii°", "dim", .red), ("III", "maj", .yellow), ("iv", "m", .green), ("v", "m", .red), ("VI", "maj", .yellow), ("VII", "maj", .red)]),
        ModalHarmonyRow(title: "Локрийский dim (min b2 b5)", cells: [("i°", "dim", .red), ("II", "maj", .yellow), ("iii", "m", .green), ("iv", "m", .green), ("V", "maj", .red), ("VI", "maj", .yellow), ("vi", "m", .green)])
    ]

    static let popularProgressions: [String: [String]] = [
        "ionian": ["I - V - vi - IV", "I - IV - V - I", "vi - IV - I - V", "I - vi - IV - V"],
        "dorian": ["i - IV - i - VII", "i - ii - IV - i", "i - VII - IV - i", "i - v - IV - i"],
        "phrygian": ["i - II - i - vii", "i - VII - VI - II", "i - bII - bVII - i", "i - iv - II - i"],
        "lydian": ["I - II - I - V", "I - II - vii - I", "I - V - II - I", "I - #iv° - V - I"],
        "mixolydian": ["I - VII - IV - I", "I - v - VII - IV", "I - IV - VII - I", "I - bVII - I - V"],
        "aeolian": ["i - VII - VI - VII", "i - VI - III - VII", "i - iv - VII - i", "i - v - VI - VII"],
        "locrian": ["i° - II - i° - iv", "i° - VI - II - i°", "i° - iv - II - i°", "i° - VII - II - i°"]
    ]
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
    static let rootText = Color(red: 0.18, green: 0.48, blue: 0.86)
    static let noteText = Color(red: 0.07, green: 0.08, blue: 0.09)
    static let openStringStroke = Color(red: 0.92, green: 0.67, blue: 0.22)
    static let primaryText = Color.white.opacity(0.92)
    static let mutedText = Color(red: 0.72, green: 0.77, blue: 0.84)
}
