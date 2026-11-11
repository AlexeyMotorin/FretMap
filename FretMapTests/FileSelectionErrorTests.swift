import XCTest
@testable import FretMap

final class FileSelectionErrorTests: XCTestCase {
    func testCancelledFileSelectionIsNotAnImportError() {
        XCTAssertTrue(FileSelectionError.isCancellation(CocoaError(.userCancelled)))
        XCTAssertFalse(FileSelectionError.isCancellation(CocoaError(.fileReadNoSuchFile)))
        XCTAssertFalse(FileSelectionError.isCancellation(NSError(domain: "Other", code: NSUserCancelledError)))
    }
}
