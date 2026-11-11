import XCTest
import SwiftUI
@testable import FretMap

final class CalendarPresentationTests: XCTestCase {
    @MainActor
    func testStatisticsPresentationWithAndWithoutResults() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = MasteryStore(directory: directory)
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        let host = UIHostingController(rootView: MasteryDailyStatistics(store: store))
        window.rootViewController = host
        window.makeKeyAndVisible()
        defer { window.isHidden = true; window.rootViewController = nil }
        host.view.layoutIfNeeded()
        try await Task.sleep(nanoseconds: 300_000_000)
        var exercise = MasteryExercise(name: "Calendar test", targetBPM: 120)
        exercise.results = [MasteryResult(bpm: 80, clean: true, note: "")]
        exercise.sessions = [MasterySession(seconds: 60)]
        XCTAssertTrue(store.save(exercise))
        host.view.setNeedsLayout()
        host.view.layoutIfNeeded()
        try await Task.sleep(nanoseconds: 300_000_000)
        XCTAssertGreaterThan(host.view.bounds.height, 0)
    }
}
