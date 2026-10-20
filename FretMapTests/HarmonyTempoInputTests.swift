import XCTest
@testable import FretMap

@MainActor
final class HarmonyTempoInputTests: XCTestCase {
    func testAcceptsIntegerTempoIncludingBounds() {
        for value in [40, 83, 150, 200] {
            XCTAssertEqual(HarmonyTempoInput.value("\(value)", previous: 120), Double(value))
        }
    }

    func testOutOfRangeInputIsClamped() {
        XCTAssertEqual(HarmonyTempoInput.value("20", previous: 120), 40)
        XCTAssertEqual(HarmonyTempoInput.value("250", previous: 120), 200)
    }

    func testIncompleteOrInvalidInputPreservesPreviousTempo() {
        for value in ["", "abc", "1.5"] {
            XCTAssertEqual(HarmonyTempoInput.value(value, previous: 120), 120)
        }
        XCTAssertEqual(HarmonyTempoInput.value(" 95 ", previous: 120), 95)
    }
}
