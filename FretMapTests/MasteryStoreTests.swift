import XCTest
@testable import FretMap

final class MasteryStoreTests: XCTestCase {
    func testArchiveAndReactivatePreserveHistoryAndSurviveRestart() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        try await MainActor.run {
            let store = MasteryStore(directory: directory)
            var exercise = MasteryExercise(name: "Test", targetBPM: 120)
            exercise.results = [MasteryResult(bpm: 90, clean: true, note: "Keep")]
            XCTAssertTrue(store.save(exercise))
            XCTAssertTrue(store.setArchived(true, id: exercise.id))
            let restored = MasteryStore(directory: directory)
            XCTAssertTrue(restored.exercises[0].isArchived)
            XCTAssertEqual(restored.exercises[0].results[0].note, "Keep")
            let settings = AppSettingsStore(persistence: InMemorySettingsPersistence())
            let backup = try restored.makeBackup(settings: settings.backupData())
            XCTAssertTrue(backup.exercises[0].isArchived)
            XCTAssertTrue(restored.setArchived(false, id: exercise.id))
            XCTAssertFalse(MasteryStore(directory: directory).exercises[0].isArchived)
            XCTAssertEqual(restored.exercises[0].results.count, 1)
        }
    }

    func testResultsAndCategoriesSurviveRestart() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        await MainActor.run {
            let store = MasteryStore(directory: directory)
            var exercise = MasteryExercise(name: "Alternate picking", targetBPM: 140, category: "Technique")
            exercise.results = [
                MasteryResult(date: Date(timeIntervalSince1970: 100), bpm: 110, clean: true, note: "Even picking"),
                MasteryResult(date: Date(timeIntervalSince1970: 200), bpm: 150, clean: false, note: "Tense"),
                MasteryResult(date: Date(timeIntervalSince1970: 300), bpm: 90, clean: true, note: "Warmup")
            ]
            exercise.sessions = [MasterySession(seconds: 125)]
            XCTAssertTrue(store.save(exercise))
            let restored = MasteryStore(directory: directory)
            XCTAssertEqual(restored.exercises.count, 1)
            XCTAssertEqual(restored.categories, ["Technique"])
            XCTAssertEqual(restored.exercises.first?.latest?.bpm, 90)
            XCTAssertEqual(restored.exercises.first?.bestCleanBPM, 110)
            XCTAssertEqual(restored.exercises.first?.practiceSeconds, 125)
            XCTAssertEqual(restored.exercises.first?.results[1].note, "Tense")
        }
    }

    func testCorruptStorageIsNotOverwritten() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("exercises.json")
        let original = Data("invalid data".utf8)
        try original.write(to: url)
        await MainActor.run {
            let store = MasteryStore(directory: directory)
            XCTAssertNotNil(store.error)
            XCTAssertFalse(store.save(MasteryExercise(name: "Test", targetBPM: 100)))
        }
        XCTAssertEqual(try Data(contentsOf: url), original)
    }

    func testInvalidBPMIsRejectedAndDeletePersists() async {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        await MainActor.run {
            let store = MasteryStore(directory: directory)
            XCTAssertFalse(store.save(MasteryExercise(name: "Test", targetBPM: 0)))
            XCTAssertFalse(store.save(MasteryExercise(name: "  ", targetBPM: 100)))
            let exercise = MasteryExercise(name: "Test", targetBPM: 100)
            XCTAssertTrue(store.save(exercise))
            store.update(exercise.id) { $0.results.append(MasteryResult(bpm: 999, clean: true, note: "")) }
            XCTAssertTrue(store.exercises[0].results.isEmpty)
            store.delete(exercise.id)
            XCTAssertTrue(MasteryStore(directory: directory).exercises.isEmpty)
        }
    }

    func testProgressUsesBestCleanResultAndIsCapped() {
        var exercise = MasteryExercise(name: "Test", targetBPM: 100)
        exercise.results = [MasteryResult(bpm: 200, clean: false, note: "")]
        XCTAssertEqual(exercise.progress, 0)
        exercise.results.append(MasteryResult(bpm: 120, clean: true, note: ""))
        XCTAssertEqual(exercise.progress, 1)
    }

    func testResetDoesNotRecordIdleTime() async {
        await MainActor.run {
            let practice = MasteryPractice()
            var sessions: [TimeInterval] = []
            practice.onSession = { sessions.append($0) }
            practice.resetTimer(minutes: 2)
            practice.finishTimer()
            practice.stopAll()
            XCTAssertEqual(practice.remaining, 120)
            XCTAssertTrue(sessions.isEmpty)
            XCTAssertFalse(practice.running)
            XCTAssertFalse(practice.metronomePlaying)
        }
    }
}
