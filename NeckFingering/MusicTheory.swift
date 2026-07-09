import SwiftUI

enum AppMode: String, CaseIterable, Identifiable, Codable {
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

enum HarmonyMode: String, CaseIterable, Identifiable, Codable {
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

enum AccidentalStyle: String, CaseIterable, Identifiable, Codable {
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

struct CustomTuningPreset: Identifiable, Equatable, Codable {
    var id: String = UUID().uuidString
    var name: String
    var stringCount: Int
    var pitchClasses: [Int]
}

struct TuningPreset: Identifiable, Equatable {
    let id: String
    let name: String
    let strings: [GuitarString]

    var stringCount: Int { strings.count }

    static func custom(stringCount: Int, pitchClasses: [Int], noteNames: [String]) -> TuningPreset {
        custom(id: "custom-\(stringCount)", name: "Кастомный", stringCount: stringCount, pitchClasses: pitchClasses, noteNames: noteNames)
    }

    static func custom(id: String, name: String, stringCount: Int, pitchClasses: [Int], noteNames: [String]) -> TuningPreset {
        let strings = Array(pitchClasses.prefix(stringCount)).enumerated().map { index, pitchClass in
            GuitarString(label: noteNames[pitchClass], pitchClass: pitchClass)
        }
        return TuningPreset(id: id, name: name, strings: strings)
    }

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

enum ChordQuality: String, CaseIterable, Identifiable, Codable {
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

enum ChordSize: String, CaseIterable, Identifiable, Codable {
    case triad
    case majorSeventh
    case dominantSeventh
    case minorSeventh
    case halfDiminished
    case diminishedSeventh

    var id: String { rawValue }

    var title: String {
        switch self {
        case .triad: "Трезвучие"
        case .majorSeventh: "maj7"
        case .dominantSeventh: "7"
        case .minorSeventh: "m7"
        case .halfDiminished: "m7b5"
        case .diminishedSeventh: "dim7"
        }
    }

    static func available(for quality: ChordQuality) -> [ChordSize] {
        switch quality {
        case .major: [.triad, .majorSeventh, .dominantSeventh]
        case .minor: [.triad, .minorSeventh, .majorSeventh]
        case .diminished: [.triad, .halfDiminished, .diminishedSeventh]
        case .augmented: [.triad, .dominantSeventh]
        }
    }
}

enum ChordExtension: String, CaseIterable, Identifiable, Codable {
    case sixth
    case thirteenth
    case flat6
    case flat13
    case add9
    case flat9
    case sharp9
    case add11
    case sharp11
    case sharp13
    case noFifth

    var id: String { rawValue }

    var title: String {
        switch self {
        case .add9: "add9"
        case .add11: "add11"
        case .sixth: "6"
        case .thirteenth: "13"
        case .flat9: "b9"
        case .sharp9: "#9"
        case .sharp11: "#11"
        case .flat6: "b6"
        case .flat13: "b13"
        case .sharp13: "#13"
        case .noFifth: "no5"
        }
    }

    var suffix: String {
        switch self {
        case .add9: "add9"
        case .add11: "add11"
        case .sixth: "6"
        case .thirteenth: "13"
        case .flat9: "b9"
        case .sharp9: "#9"
        case .sharp11: "#11"
        case .flat6: "b6"
        case .flat13: "b13"
        case .sharp13: "#13"
        case .noFifth: "(no5)"
        }
    }

    var tone: ChordTone? {
        switch self {
        case .add9: ChordTone(interval: 2, degree: "9")
        case .add11: ChordTone(interval: 5, degree: "11")
        case .sixth: ChordTone(interval: 9, degree: "6")
        case .thirteenth: ChordTone(interval: 9, degree: "13")
        case .flat9: ChordTone(interval: 1, degree: "b9")
        case .sharp9: ChordTone(interval: 3, degree: "#9")
        case .sharp11: ChordTone(interval: 6, degree: "#11")
        case .flat6: ChordTone(interval: 8, degree: "b6")
        case .flat13: ChordTone(interval: 8, degree: "b13")
        case .sharp13: ChordTone(interval: 10, degree: "#13")
        case .noFifth: nil
        }
    }

    func isAvailable(for quality: ChordQuality) -> Bool {
        self != .noFifth || quality == .major || quality == .minor
    }
}

struct ChordTone {
    let interval: Int
    let degree: String
}

struct ChordSettings: Codable {
    var root: Int = 0
    var quality: ChordQuality = .major
    var size: ChordSize = .triad
    var startString: Int = 6
    var shapeID: String = "major-e"
    var extensions: [ChordExtension] = []

    init(
        root: Int = 0,
        quality: ChordQuality = .major,
        size: ChordSize = .triad,
        startString: Int = 6,
        shapeID: String = "major-e",
        extensions: [ChordExtension] = []
    ) {
        self.root = root
        self.quality = quality
        self.size = size
        self.startString = startString
        self.shapeID = shapeID
        self.extensions = extensions
    }

    enum CodingKeys: String, CodingKey {
        case root
        case quality
        case size
        case startString
        case shapeID
        case extensions
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        root = try container.decodeIfPresent(Int.self, forKey: .root) ?? 0
        quality = try container.decodeIfPresent(ChordQuality.self, forKey: .quality) ?? .major
        size = try container.decodeIfPresent(ChordSize.self, forKey: .size) ?? .triad
        startString = try container.decodeIfPresent(Int.self, forKey: .startString) ?? 6
        shapeID = try container.decodeIfPresent(String.self, forKey: .shapeID) ?? "major-e"
        extensions = try container.decodeIfPresent([ChordExtension].self, forKey: .extensions) ?? []
    }

    var displaySuffix: String {
        let baseSuffix: String = switch size {
        case .triad:
            switch quality {
            case .major: ""
            case .minor: "m"
            case .augmented: "aug"
            case .diminished: "dim"
            }
        case .majorSeventh:
            switch quality {
            case .major: "maj7"
            case .minor: "m(maj7)"
            case .augmented: "aug(maj7)"
            case .diminished: "dim(maj7)"
            }
        case .dominantSeventh:
            switch quality {
            case .major: "7"
            case .minor: "m7"
            case .augmented: "aug7"
            case .diminished: "dim7"
            }
        case .minorSeventh: "m7"
        case .halfDiminished: "m7b5"
        case .diminishedSeventh: "dim7"
        }

        var suffix = baseSuffix
        for item in extensionItems {
            if item == .noFifth {
                suffix += item.suffix
            } else if baseSuffix.isEmpty || baseSuffix == "m" || baseSuffix == "aug" || baseSuffix == "dim" {
                suffix += item.suffix
            } else {
                suffix += "/\(item.suffix)"
            }
        }
        return suffix
    }

    var extensionItems: [ChordExtension] {
        let allowed = extensions.filter { $0.isAvailable(for: quality) }
        return ChordExtension.allCases.filter { allowed.contains($0) }
    }

    var omitsFifth: Bool {
        extensionItems.contains(.noFifth)
    }

    var hasExtensions: Bool {
        !extensionItems.isEmpty
    }

    var baseTones: [ChordTone] {
        var tones = quality.triadIntervals.enumerated().map { index, interval in
            ChordTone(interval: interval, degree: quality.triadDegrees[index])
        }

        switch size {
        case .triad:
            break
        case .majorSeventh:
            tones.append(ChordTone(interval: 11, degree: "7"))
        case .dominantSeventh, .minorSeventh:
            tones.append(ChordTone(interval: 10, degree: "b7"))
        case .halfDiminished:
            tones = [
                ChordTone(interval: 0, degree: "1"),
                ChordTone(interval: 3, degree: "b3"),
                ChordTone(interval: 6, degree: "b5"),
                ChordTone(interval: 10, degree: "b7")
            ]
        case .diminishedSeventh:
            tones = [
                ChordTone(interval: 0, degree: "1"),
                ChordTone(interval: 3, degree: "b3"),
                ChordTone(interval: 6, degree: "b5"),
                ChordTone(interval: 9, degree: "bb7")
            ]
        }

        if omitsFifth {
            tones.removeAll { $0.degree == "5" }
        }
        return tones
    }

    var extensionTones: [ChordTone] {
        extensionItems.compactMap(\.tone)
    }

    var tones: [ChordTone] {
        uniqueTones(extensionTones + baseTones)
    }

    var intervals: Set<Int> { Set(tones.map(\.interval)) }
    var requiredIntervals: Set<Int> { Set(baseTones.map(\.interval)) }

    func toneLabel(for interval: Int) -> String? {
        tones.first { $0.interval == interval }?.degree
    }

    private func uniqueTones(_ tones: [ChordTone]) -> [ChordTone] {
        var seen: Set<Int> = []
        return tones.filter { tone in
            guard !seen.contains(tone.interval) else { return false }
            seen.insert(tone.interval)
            return true
        }
    }
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
        return barres.compactMap { barre in
            let fret = barre.fret + shift
            guard fret > 0 else { return nil }
            return ChordBarre(fret: fret, fromStringNumber: barre.fromStringNumber, toStringNumber: barre.toStringNumber)
        }
    }

    private func transpositionShift(to root: Int) -> Int {
        let semitoneShift = (root - baseRoot + 12) % 12
        let shiftedFrets = notes.map { $0.fret + semitoneShift }
        if shiftedFrets.min() ?? 0 >= 12 {
            return semitoneShift - 12
        }
        return semitoneShift
    }

    static var all: [ChordShape] { ChordFingeringDatabase.all }
}

struct FretPosition: Hashable, Identifiable, Codable {
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
        MusicDatabase.popularProgressions(for: scale)
    }
}

enum ChordIdentifier {
    static func identify(pitchClasses: Set<Int>, noteNames: [String]) -> String? {
        guard pitchClasses.count >= 3 else { return nil }

        let qualities: [(String, [Int])] = [
            ("maj7", [0, 4, 7, 11]),
            ("7", [0, 4, 7, 10]),
            ("m7", [0, 3, 7, 10]),
            ("m7b5", [0, 3, 6, 10]),
            ("dim7", [0, 3, 6, 9]),
            ("maj", [0, 4, 7]),
            ("m", [0, 3, 7]),
            ("aug", [0, 4, 8]),
            ("dim", [0, 3, 6])
        ]

        for root in 0..<12 {
            let intervals = Set(pitchClasses.map { ($0 - root + 12) % 12 })
            for quality in qualities where Set(quality.1) == intervals {
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
