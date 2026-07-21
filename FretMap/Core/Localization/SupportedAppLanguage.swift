import Foundation

enum SupportedAppLanguage: String, CaseIterable, Identifiable {
    case russian = "ru"
    case english = "en"
    case german = "de"
    case simplifiedChinese = "zh-Hans"
    case arabic = "ar"
    case spanish = "es"
    case french = "fr"
    case brazilianPortuguese = "pt-BR"
    case japanese = "ja"
    case korean = "ko"

    var id: String { rawValue }
    var locale: Locale { Locale(identifier: rawValue) }
}

enum L10n {
    static func string(_ key: String) -> String {
        NSLocalizedString(key, comment: "")
    }
}
