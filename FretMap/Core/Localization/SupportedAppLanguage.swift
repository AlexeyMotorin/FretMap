import Foundation

nonisolated enum SupportedAppLanguage: String, CaseIterable, Identifiable {
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

    var nativeName: String {
        switch self {
        case .russian: "Русский"
        case .english: "English"
        case .german: "Deutsch"
        case .simplifiedChinese: "简体中文"
        case .arabic: "العربية"
        case .spanish: "Español"
        case .french: "Français"
        case .brazilianPortuguese: "Português (Brasil)"
        case .japanese: "日本語"
        case .korean: "한국어"
        }
    }

    static let preferenceKey = "mac.app.language"

    static func resolved(_ preference: String) -> SupportedAppLanguage? {
        SupportedAppLanguage(rawValue: preference)
    }
}

nonisolated enum L10n {
    static func string(_ key: String) -> String {
        #if targetEnvironment(macCatalyst)
        if let language = SupportedAppLanguage.resolved(UserDefaults.standard.string(forKey: SupportedAppLanguage.preferenceKey) ?? ""),
           let path = Bundle.main.path(forResource: language.rawValue, ofType: "lproj"),
           let bundle = Bundle(path: path) {
            return bundle.localizedString(forKey: key, value: nil, table: nil)
        }
        #endif
        return NSLocalizedString(key, comment: "")
    }
}
