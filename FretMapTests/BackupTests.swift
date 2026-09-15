import XCTest
import UIKit
import PDFKit
@testable import FretMap

final class BackupTests: XCTestCase {
    func testRoundTripRestoresSettingsExercisesHistoryAndPhotos() async throws {
        let sourceURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let targetURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer {
            try? FileManager.default.removeItem(at: sourceURL)
            try? FileManager.default.removeItem(at: targetURL)
        }
        try await MainActor.run {
            let settings = AppSettingsStore(persistence: InMemorySettingsPersistence())
            settings.rootNote = 7
            settings.favoriteProgressionIDs = ["ionian-secondary"]
            let source = MasteryStore(directory: sourceURL)
            var exercise = MasteryExercise(name: "Picking", targetBPM: 130, category: "Technique", comment: "Stay relaxed")
            exercise.difficulty = .medium
            exercise.results.append(MasteryResult(bpm: 95, clean: true, note: "Good"))
            exercise.sessions.append(MasterySession(seconds: 123))
            XCTAssertTrue(source.save(exercise))
            let image = UIGraphicsImageRenderer(size: CGSize(width: 12, height: 12)).image { context in
                UIColor.red.setFill()
                context.fill(CGRect(x: 0, y: 0, width: 12, height: 12))
            }
            source.addPhoto(image, to: exercise.id)
            let pdf = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 200, height: 300)).pdfData { context in
                context.beginPage()
                ("Tablature" as NSString).draw(at: CGPoint(x: 20, y: 20), withAttributes: nil)
            }
            try source.addPDF(data: pdf, name: "Tablature.pdf", to: exercise.id)
            XCTAssertThrowsError(try source.addPDF(data: pdf, name: "Second.pdf", to: exercise.id))
            XCTAssertEqual(source.exercises[0].attachedPDFs.count, 1)
            let data = try JSONEncoder().encode(source.makeBackup(settings: settings.backupData()))
            let backup = try JSONDecoder().decode(FretMapBackup.self, from: data)
            let prepared = try AppSettingsStore.preparedBackup(backup.settings)
            let target = MasteryStore(directory: targetURL)
            XCTAssertTrue(target.save(MasteryExercise(name: "Old", targetBPM: 60)))
            try target.restoreBackup(backup)
            let restoredSettings = AppSettingsStore(persistence: InMemorySettingsPersistence())
            restoredSettings.applyBackup(prepared)
            XCTAssertEqual(restoredSettings.rootNote, 7)
            XCTAssertEqual(restoredSettings.favoriteProgressionIDs, ["ionian-secondary"])
            let restored = MasteryStore(directory: targetURL)
            XCTAssertEqual(restored.exercises.count, 1)
            XCTAssertEqual(restored.exercises.first?.id, exercise.id)
            XCTAssertEqual(restored.exercises.first?.comment, "Stay relaxed")
            XCTAssertEqual(restored.exercises.first?.difficulty, .medium)
            XCTAssertEqual(restored.exercises.first?.latest?.bpm, 95)
            XCTAssertEqual(restored.exercises.first?.practiceSeconds, 123)
            let name = try XCTUnwrap(restored.exercises.first?.photos.first)
            XCTAssertNotNil(UIImage(contentsOfFile: restored.photoURL(name).path))
            let attachedPDF = try XCTUnwrap(restored.exercises.first?.attachedPDFs.first)
            XCTAssertEqual(attachedPDF.name, "Tablature.pdf")
            XCTAssertEqual(PDFDocument(url: restored.photoURL(attachedPDF.id))?.pageCount, 1)
            XCTAssertThrowsError(try restored.addPDF(data: Data("not a PDF".utf8), name: "bad.pdf", to: exercise.id))
            XCTAssertEqual(restored.exercises.first?.attachedPDFs.count, 1)

            var legacyJSON = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
            legacyJSON["version"] = 1
            legacyJSON.removeValue(forKey: "documents")
            var oldExercises = try XCTUnwrap(legacyJSON["exercises"] as? [[String: Any]])
            for index in oldExercises.indices { oldExercises[index].removeValue(forKey: "pdfs") }
            legacyJSON["exercises"] = oldExercises
            let legacy = try JSONDecoder().decode(FretMapBackup.self, from: JSONSerialization.data(withJSONObject: legacyJSON))
            try legacy.validate()
            XCTAssertTrue(legacy.exercises[0].attachedPDFs.isEmpty)
        }
    }

    func testInvalidBackupDoesNotReplaceExistingData() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        try await MainActor.run {
            let store = MasteryStore(directory: directory)
            let exercise = MasteryExercise(name: "Keep me", targetBPM: 100)
            XCTAssertTrue(store.save(exercise))
            let settings = AppSettingsStore(persistence: InMemorySettingsPersistence())
            var backup = try store.makeBackup(settings: settings.backupData())
            backup.version = 999
            XCTAssertThrowsError(try store.restoreBackup(backup))
            XCTAssertEqual(MasteryStore(directory: directory).exercises.first?.id, exercise.id)
            var missingPhoto = MasteryExercise(name: "Bad", targetBPM: 100)
            missingPhoto.photos = ["missing.jpg"]
            let missing = FretMapBackup(settings: backup.settings, exercises: [missingPhoto], photos: [:])
            XCTAssertThrowsError(try store.restoreBackup(missing))
            XCTAssertEqual(MasteryStore(directory: directory).exercises.first?.id, exercise.id)
            XCTAssertThrowsError(try AppSettingsStore.preparedBackup(Data("bad".utf8)))
        }
    }
}
