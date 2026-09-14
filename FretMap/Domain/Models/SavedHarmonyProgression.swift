import Foundation

enum SavedHarmonySource: String, Codable {
    case functional
    case modal
}

struct SavedHarmonyProgression: Identifiable, Codable, Equatable {
    var id: String = UUID().uuidString
    var name: String
    var source: SavedHarmonySource
    var root: Int
    var functionalMode: FunctionalKeyMode?
    var modalMode: ModalBuilderMode?
    var degrees: [Int]
    var chordKinds: [FunctionalChordKind]
    var rating: Int = 3

    var scale: ScalePattern {
        switch source {
        case .functional:
            return functionalMode == .minor ? .aeolian : .ionian
        case .modal:
            switch modalMode ?? .dorian {
            case .dorian: return .dorian
            case .phrygian: return .phrygian
            case .lydian: return .lydian
            case .mixolydian: return .mixolydian
            case .locrian: return .locrian
            }
        }
    }

    var degreeTitles: [String] {
        switch source {
        case .functional:
            return (functionalMode ?? .major).degreeTitles
        case .modal:
            return (modalMode ?? .dorian).cells.map(\.degree)
        }
    }

    var popularProgression: PopularProgression {
        let bars = degrees.map { degree -> [String] in
            let index = min(max(degree - 1, 0), degreeTitles.count - 1)
            return [degreeTitles[index]]
        }
        var progression = PopularProgression(
            id: "\(scale.id)-saved-\(id)",
            title: name,
            category: source == .functional ? L10n.string("Функциональная") : L10n.string("Модальная"),
            bars: bars,
            popularity: rating,
            color: .neutral
        )
        progression.functionalMode = source == .functional ? functionalMode : nil
        return progression
    }

    var seventhChordIndexes: [Int] {
        chordKinds.enumerated().compactMap { index, kind in
            kind == .seventh ? index : nil
        }
    }
}
