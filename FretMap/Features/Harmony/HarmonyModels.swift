import Foundation

enum FunctionalKeyMode: String, CaseIterable, Identifiable, Codable {
    case major
    case minor

    var id: String { rawValue }

    var title: String {
        switch self {
        case .major: String(localized: "Мажор")
        case .minor: String(localized: "Минор")
        }
    }

    var intervals: [Int] {
        switch self {
        case .major: [0, 2, 4, 5, 7, 9, 11]
        case .minor: [0, 2, 3, 5, 7, 8, 11]
        }
    }

    var qualities: [String] {
        switch self {
        case .major: ["", "m", "m", "", "", "m", "dim"]
        case .minor: ["m", "dim", "", "m", "", "", "dim"]
        }
    }

    var seventhQualities: [String] {
        switch self {
        case .major: ["maj7", "m7", "m7", "maj7", "7", "m7", "m7b5"]
        case .minor: ["m7", "m7b5", "maj7", "m7", "7", "maj7", "dim7"]
        }
    }

    var degreeTitles: [String] {
        switch self {
        case .major: ["I", "ii", "iii", "IV", "V", "vi", "vii°"]
        case .minor: ["i", "ii°", "III", "iv", "V", "VI", "vii°"]
        }
    }
}

enum FunctionalChordKind: String, CaseIterable, Identifiable, Codable, Hashable {
    case triad
    case seventh
    case mixed

    var id: String { rawValue }

    var title: String {
        switch self {
        case .triad: String(localized: "Трезвучие")
        case .seventh: String(localized: "Септаккорд")
        case .mixed: String(localized: "Смешанный")
        }
    }
}

enum ModalBuilderMode: String, CaseIterable, Identifiable, Codable {
    case dorian
    case phrygian
    case lydian
    case mixolydian
    case locrian

    var id: String { rawValue }

    var title: String {
        switch self {
        case .dorian: String(localized: "Дорийский")
        case .phrygian: String(localized: "Фригийский")
        case .lydian: String(localized: "Лидийский")
        case .mixolydian: String(localized: "Миксолидийский")
        case .locrian: String(localized: "Локрийский")
        }
    }

    var intervals: [Int] {
        switch self {
        case .dorian: [0, 2, 3, 5, 7, 9, 10]
        case .phrygian: [0, 1, 3, 5, 7, 8, 10]
        case .lydian: [0, 2, 4, 6, 7, 9, 11]
        case .mixolydian: [0, 2, 4, 5, 7, 9, 10]
        case .locrian: [0, 1, 3, 5, 6, 8, 10]
        }
    }

    var cells: [(degree: String, chord: String, color: HarmonyColor)] {
        switch self {
        case .dorian: [("i", "m", .green), ("ii", "m", .green), ("bIII", "maj", .yellow), ("IV", "maj", .green), ("v", "m", .red), ("vi°", "dim", .red), ("bVII", "maj", .red)]
        case .phrygian: [("i", "m", .green), ("bII", "maj", .green), ("bIII", "maj", .yellow), ("iv", "m", .red), ("v°", "dim", .red), ("bVI", "maj", .yellow), ("bvii", "m", .green)]
        case .lydian: [("I", "maj", .green), ("II", "maj", .green), ("iii", "m", .yellow), ("#iv°", "dim", .red), ("V", "maj", .red), ("vi", "m", .yellow), ("vii", "m", .green)]
        case .mixolydian: [("I", "maj", .green), ("ii", "m", .yellow), ("iii°", "dim", .red), ("IV", "maj", .red), ("v", "m", .green), ("vi", "m", .yellow), ("bVII", "maj", .green)]
        case .locrian: [("i°", "dim", .red), ("bII", "maj", .yellow), ("biii", "m", .green), ("iv", "m", .green), ("bV", "maj", .red), ("bVI", "maj", .yellow), ("bvii", "m", .green)]
        }
    }
}

enum PopularCollectionMode: String, CaseIterable, Identifiable, Codable {
    case popular
    case favorites

    var id: String { rawValue }

    var title: String {
        switch self {
        case .popular: String(localized: "Популярные")
        case .favorites: String(localized: "Избранное")
        }
    }
}

enum PopularSortMode: String, CaseIterable, Identifiable, Codable {
    case defaultOrder
    case ratingDescending

    var id: String { rawValue }

    var title: String {
        switch self {
        case .defaultOrder: String(localized: "По умолчанию")
        case .ratingDescending: String(localized: "По рейтингу")
        }
    }
}

enum PopularSlashChordConfiguration: String, CaseIterable, Identifiable, Codable {
    case triadTriad
    case triadSeventh
    case seventhSeventh
    case secondTriad
    case secondSeventh

    var id: String { rawValue }
    var secondIsActive: Bool { true }
    var firstIsSeventh: Bool { self == .seventhSeventh }

    var firstIsActive: Bool {
        self != .secondTriad && self != .secondSeventh
    }

    var secondIsSeventh: Bool {
        self == .triadSeventh || self == .seventhSeventh || self == .secondSeventh
    }
}
