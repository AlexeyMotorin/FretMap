import XCTest
@testable import FretMap

final class LocalizationTests: XCTestCase {
    private let supportedLocalizations = [
        "ru", "en", "de", "zh-Hans", "ar",
        "es", "fr", "pt-BR", "ja", "ko"
    ]

    func testEverySupportedLocalizationIsBundledAndComplete() throws {
        var expectedKeys: Set<String>?

        for localization in supportedLocalizations {
            let url = try XCTUnwrap(
                Bundle.main.url(
                    forResource: "Localizable",
                    withExtension: "strings",
                    subdirectory: nil,
                    localization: localization
                ),
                "Missing Localizable.strings for \(localization)"
            )
            let data = try Data(contentsOf: url)
            let dictionary = try XCTUnwrap(
                PropertyListSerialization.propertyList(from: data, format: nil)
                    as? [String: String]
            )

            XCTAssertFalse(dictionary.isEmpty)
            XCTAssertFalse(dictionary["Аккорды", default: ""].isEmpty)

            let keys = Set(dictionary.keys)
            if let expectedKeys {
                XCTAssertEqual(keys, expectedKeys, "Localization keys differ for \(localization)")
            } else {
                expectedKeys = keys
            }
        }
    }

    func testArabicLocalizationUsesRightToLeftLayoutDirection() {
        XCTAssertEqual(
            Locale.Language(identifier: "ar").characterDirection,
            .rightToLeft
        )
    }
}
