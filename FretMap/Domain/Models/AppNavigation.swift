import Foundation

enum AppMode: String, CaseIterable, Identifiable, Codable {
    case chords
    case modes
    case harmony
    case mastery

    var id: String { rawValue }

    var title: String {
        switch self {
        case .chords: L10n.string("Аккорды")
        case .modes: L10n.string("Лады")
        case .harmony: L10n.string("Гармония")
        case .mastery: L10n.string("mastery.title")
        }
    }
}

enum HarmonyMode: String, CaseIterable, Identifiable, Codable {
    case functional
    case modal
    case popular
    case saved

    var id: String { rawValue }

    var title: String {
        switch self {
        case .functional: L10n.string("Функциональная")
        case .modal: L10n.string("Модальная")
        case .popular: L10n.string("Популярные")
        case .saved: L10n.string("Мои")
        }
    }
}
