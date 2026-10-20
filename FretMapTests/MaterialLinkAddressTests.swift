import XCTest
@testable import FretMap

final class MaterialLinkAddressTests: XCTestCase {
    func testWebAddressesWithAndWithoutScheme() {
        XCTAssertEqual(MaterialLinkAddress.url(from: " example.com/lesson ")?.absoluteString, "https://example.com/lesson")
        XCTAssertEqual(MaterialLinkAddress.url(from: "https://example.com/lesson")?.absoluteString, "https://example.com/lesson")
        XCTAssertEqual(MaterialLinkAddress.url(from: "http://example.com")?.scheme, "http")
    }

    func testInvalidAndUnsafeAddressesAreRejected() {
        for input in ["", " ", "not a link", "https://", "file:///tmp/photo", "javascript:alert(1)", "https://user:password@example.com", "example"] {
            XCTAssertNil(MaterialLinkAddress.url(from: input), input)
        }
    }
}
