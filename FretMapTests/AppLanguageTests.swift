import XCTest
@testable import FretMap

final class AppLanguageTests: XCTestCase {
    func testEverySupportedLanguageHasADistinctNativeName() {
        let languages = SupportedAppLanguage.allCases
        XCTAssertEqual(Set(languages.map(\.nativeName)).count, languages.count)
        XCTAssertTrue(languages.allSatisfy { !$0.nativeName.isEmpty })
    }

    func testSystemAndInvalidPreferencesFallBackToSystem() {
        XCTAssertNil(SupportedAppLanguage.resolved(""))
        XCTAssertNil(SupportedAppLanguage.resolved("invalid"))
    }

    func testSavedLanguagesResolveWithoutDependingOnSystemLocale() {
        for language in SupportedAppLanguage.allCases {
            XCTAssertEqual(SupportedAppLanguage.resolved(language.rawValue), language)
            XCTAssertEqual(language.locale.identifier, language.rawValue)
        }
    }
}
