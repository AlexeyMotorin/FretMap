import XCTest
@testable import FretMap

@MainActor
final class MacFretboardSizingTests: XCTestCase {
    func testSidebarCanExpandToOneThirdOfWindow() {
        XCTAssertEqual(MacSidebarSizing.fitted(600, in: 1800), 600)
        XCTAssertEqual(MacSidebarSizing.fitted(900, in: 1800), 600)
        XCTAssertEqual(MacSidebarSizing.fitted(100, in: 1800), 320)
    }

    func testSidebarFitsSmallerWindowAndRestoresPreferredWidth() {
        XCTAssertEqual(MacSidebarSizing.fitted(600, in: 1200), 400)
        XCTAssertEqual(MacSidebarSizing.fitted(600, in: 1800), 600)
    }

    func testLargerWindowDoesNotStretchPreferredSize() {
        let preferred = CGSize(width: 1000, height: 600)
        XCTAssertEqual(MacFretboardSizing.fitted(preferred, in: CGSize(width: 1100, height: 700)), preferred)
        XCTAssertEqual(MacFretboardSizing.fitted(preferred, in: CGSize(width: 1800, height: 1200)), preferred)
    }

    func testDragResizesAroundCenterAndHonorsMinimum() {
        let start = CGSize(width: 1000, height: 600)
        let available = CGSize(width: 1800, height: 1200)
        XCTAssertEqual(MacFretboardSizing.resized(from: start, translation: CGSize(width: 100, height: 80), in: available),
                       CGSize(width: 1200, height: 760))
        XCTAssertEqual(MacFretboardSizing.resized(from: start, translation: CGSize(width: -900, height: -900), in: available),
                       MacFretboardSizing.minimumSize)
    }

    func testBoardFitsSmallWindowWithoutLosingPreferredSize() {
        let preferred = CGSize(width: 1200, height: 800)
        XCTAssertEqual(MacFretboardSizing.fitted(preferred, in: CGSize(width: 800, height: 650)),
                       CGSize(width: 800, height: 650))
        XCTAssertEqual(MacFretboardSizing.fitted(preferred, in: CGSize(width: 1600, height: 1000)), preferred)
    }
}
