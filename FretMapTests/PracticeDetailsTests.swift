import XCTest
@testable import FretMap

final class PracticeDetailsTests: XCTestCase {
    func testDetailsRoundTripAndLegacyDecoding() throws {
        let result = MasteryResult(bpm: 100, clean: true, note: "",
            subdivision: .triplets, cleanRepetitions: 5, difficulty: .medium)
        let data = try JSONEncoder().encode(result)
        let decoded = try JSONDecoder().decode(MasteryResult.self, from: data)
        XCTAssertEqual(decoded.subdivision, .triplets)
        XCTAssertEqual(decoded.cleanRepetitions, 5)
        XCTAssertEqual(decoded.difficulty, .medium)
        var old = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        for key in ["subdivision", "cleanRepetitions", "difficulty"] { old.removeValue(forKey: key) }
        let legacy = try JSONDecoder().decode(MasteryResult.self, from: JSONSerialization.data(withJSONObject: old))
        XCTAssertNil(legacy.subdivision)
        XCTAssertNil(legacy.cleanRepetitions)
        XCTAssertNil(legacy.difficulty)
        XCTAssertEqual(legacy.bpm, 100)
    }

    func testExerciseSubdivisionPersistsWithoutChangingOldResults() async throws {
        try await MainActor.run {
            let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
            defer { try? FileManager.default.removeItem(at: directory) }
            let store = MasteryStore(directory: directory)
            var exercise = MasteryExercise(name: "Test", targetBPM: 120)
            exercise.subdivision = .eighths
            exercise.results = [MasteryResult(bpm: 90, clean: true, note: "", subdivision: .eighths, cleanRepetitions: 3, difficulty: .hard)]
            XCTAssertTrue(store.save(exercise))
            exercise.subdivision = .sixteenths
            XCTAssertTrue(store.save(exercise))
            let loaded = try XCTUnwrap(MasteryStore(directory: directory).exercises.first)
            XCTAssertEqual(loaded.subdivision, .sixteenths)
            XCTAssertEqual(loaded.results.first?.subdivision, .eighths)
            exercise.results[0].cleanRepetitions = 101
            XCTAssertFalse(store.save(exercise))
        }
    }
}
