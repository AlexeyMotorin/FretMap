import XCTest
@testable import FretMap

final class TuningCatalogTests: XCTestCase {
    func testCompatibleTuningsMatchRequestedStringCount() {
        let catalog = TuningCatalog()

        for stringCount in 4...8 {
            let tunings = catalog.compatibleTunings(stringCount: stringCount)
            XCTAssertFalse(tunings.isEmpty)
            XCTAssertTrue(tunings.allSatisfy { $0.stringCount == stringCount })
        }
    }

    func testCustomTuningMenuIDRoundTrip() {
        let catalog = TuningCatalog()
        let id = "custom-tuning-id"

        XCTAssertEqual(
            catalog.customTuningID(fromMenuID: catalog.menuID(forCustomTuningID: id)),
            id
        )
        XCTAssertNil(catalog.customTuningID(fromMenuID: "standard-6"))
    }

    func testDefaultPitchClassesContainOneValuePerString() {
        let catalog = TuningCatalog()

        for stringCount in 4...8 {
            XCTAssertEqual(
                catalog.defaultPitchClasses(stringCount: stringCount).count,
                stringCount
            )
        }
    }
}
