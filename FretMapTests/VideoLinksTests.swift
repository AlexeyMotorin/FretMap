import XCTest
@testable import FretMap

final class VideoLinksTests: XCTestCase {
    func testUnlimitedLinksAndSafeSchemes() {
        var exercise = MasteryExercise(name: "Test", targetBPM: 120)
        XCTAssertTrue(exercise.hasValidVideoLinks)
        exercise.videoLinks = (1...5).map { "https://example.com/video/\($0)" }
        XCTAssertTrue(exercise.hasValidVideoLinks)
        exercise.videoLinks?.append("https://example.com/6")
        XCTAssertTrue(exercise.hasValidVideoLinks)
        exercise.videoLinks = ["file:///private/test"]
        XCTAssertFalse(exercise.hasValidVideoLinks)
        exercise.videoLinks = ["https://example.com", "https://example.com"]
        XCTAssertFalse(exercise.hasValidVideoLinks)
    }

    func testRoundTripAndOlderExercise() throws {
        var exercise = MasteryExercise(name: "Test", targetBPM: 120)
        exercise.videoLinks = ["https://example.com/video"]
        exercise.linkTitles = ["https://example.com/video": "Study material"]
        let data = try JSONEncoder().encode(exercise)
        XCTAssertEqual(try JSONDecoder().decode(MasteryExercise.self, from: data).videoLinks, exercise.videoLinks)
        XCTAssertEqual(try JSONDecoder().decode(MasteryExercise.self, from: data).linkTitles, exercise.linkTitles)
        var old = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        old.removeValue(forKey: "videoLinks")
        old.removeValue(forKey: "linkTitles")
        XCTAssertNil(try JSONDecoder().decode(MasteryExercise.self, from: JSONSerialization.data(withJSONObject: old)).videoLinks)
    }
}
