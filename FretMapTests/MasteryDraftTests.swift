import XCTest
import UIKit
@testable import FretMap

final class MasteryDraftTests: XCTestCase {
    func testExerciseDraftDoesNotPersistUntilCommitAndCanBeDiscarded() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        await MainActor.run {
            let store = MasteryStore(directory: directory)
            let exercise = MasteryExercise(name: "Riff", targetBPM: 120)
            XCTAssertTrue(store.save(exercise))
            store.beginEditingExercise(exercise.id)
            XCTAssertFalse(store.hasUnsavedExerciseChanges(exercise.id))
            store.update(exercise.id) { $0.results.append(MasteryResult(bpm: 90, clean: true, note: "Test")) }
            XCTAssertTrue(store.hasUnsavedExerciseChanges(exercise.id))
            XCTAssertTrue(MasteryStore(directory: directory).exercises[0].results.isEmpty)
            XCTAssertTrue(store.commitExercise(exercise.id))
            XCTAssertEqual(MasteryStore(directory: directory).exercises[0].results.count, 1)
            store.beginEditingExercise(exercise.id)
            store.update(exercise.id) { $0.name = "Changed" }
            store.discardExerciseChanges(exercise.id)
            XCTAssertEqual(store.exercise(exercise.id)?.name, "Riff")
        }
    }

    func testRemovingPDFInDraftPreservesFileUntilCommit() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        try await MainActor.run {
            let store = MasteryStore(directory: directory)
            let song = MasterySong(title: "Song", artist: "Artist")
            XCTAssertTrue(store.save(song))
            let data = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 100, height: 100)).pdfData { $0.beginPage() }
            try store.addSongPDF(data: data, name: "Tab.pdf", to: song.id)
            let pdf = try XCTUnwrap(store.song(song.id)?.attachedPDFs.first)
            store.beginEditingSong(song.id)
            store.removeSongPDF(pdf.id, from: song.id)
            XCTAssertTrue(FileManager.default.fileExists(atPath: store.photoURL(pdf.id).path))
            store.discardSongChanges(song.id)
            XCTAssertEqual(store.song(song.id)?.attachedPDFs.count, 1)
            store.beginEditingSong(song.id)
            store.removeSongPDF(pdf.id, from: song.id)
            XCTAssertTrue(store.commitSong(song.id))
            XCTAssertFalse(FileManager.default.fileExists(atPath: store.photoURL(pdf.id).path))
            XCTAssertTrue(MasteryStore(directory: directory).songs[0].attachedPDFs.isEmpty)
        }
    }

    func testFailedSaveKeepsDraft() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        try await MainActor.run {
            let store = MasteryStore(directory: directory)
            let song = MasterySong(title: "Original", artist: "Artist")
            XCTAssertTrue(store.save(song))
            store.beginEditingSong(song.id)
            store.updateSong(song.id) { $0.title = "Draft" }
            let snapshot = directory.appendingPathComponent("mastery.json")
            try FileManager.default.removeItem(at: snapshot)
            try FileManager.default.createDirectory(at: snapshot, withIntermediateDirectories: false)
            XCTAssertFalse(store.commitSong(song.id))
            XCTAssertEqual(store.song(song.id)?.title, "Draft")
            XCTAssertTrue(store.hasUnsavedSongChanges(song.id))
        }
    }

    func testSongMaterialsAndPartMaterialsRestoreIndependently() async throws {
        let sourceURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let targetURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer {
            try? FileManager.default.removeItem(at: sourceURL)
            try? FileManager.default.removeItem(at: targetURL)
        }
        try await MainActor.run {
            let store = MasteryStore(directory: sourceURL)
            var song = MasterySong(title: "Song", artist: "Artist")
            song.materialLinks = ["https://example.com/song"]
            XCTAssertTrue(store.save(song))
            var part = MasteryExercise(name: "Intro", targetBPM: 120)
            part.songID = song.id
            part.videoLinks = ["https://example.com/part"]
            XCTAssertTrue(store.save(part))
            let data = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 100, height: 100)).pdfData { $0.beginPage() }
            try store.addSongPDF(data: data, name: "Song.pdf", to: song.id)
            try store.addPDF(data: data, name: "Intro.pdf", to: part.id)
            let target = MasteryStore(directory: targetURL)
            try target.restoreBackup(store.makeBackup(settings: Data()))
            XCTAssertEqual(target.songs[0].materialLinks, song.materialLinks)
            XCTAssertEqual(target.exercises[0].videoLinks, part.videoLinks)
            let songPDF = try XCTUnwrap(target.songs[0].attachedPDFs.first)
            let partPDF = try XCTUnwrap(target.exercises[0].attachedPDFs.first)
            XCTAssertNotEqual(songPDF.id, partPDF.id)
            XCTAssertEqual(try Data(contentsOf: target.photoURL(songPDF.id)), data)
            XCTAssertEqual(try Data(contentsOf: target.photoURL(partPDF.id)), data)
        }
    }

    func testLegacyBackupWithoutSongsDecodes() throws {
        let backup = FretMapBackup(settings: Data(), exercises: [], photos: [:])
        var json = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(backup)) as? [String: Any])
        json.removeValue(forKey: "songs")
        json["version"] = 2
        let decoded = try JSONDecoder().decode(FretMapBackup.self, from: JSONSerialization.data(withJSONObject: json))
        XCTAssertTrue(decoded.songs.isEmpty)
        try decoded.validate()
    }

    func testSongCompletionAndReactivation() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        await MainActor.run {
            let store = MasteryStore(directory: directory)
            let song = MasterySong(title: "Song", artist: "Artist")
            XCTAssertTrue(store.save(song))
            XCTAssertFalse(store.setSongArchived(true, id: song.id))
            var part = MasteryExercise(name: "Intro", targetBPM: 120)
            part.songID = song.id
            XCTAssertTrue(store.save(part))
            XCTAssertFalse(store.setSongArchived(true, id: song.id))
            XCTAssertTrue(store.setArchived(true, id: part.id))
            XCTAssertTrue(store.setSongArchived(true, id: song.id))
            XCTAssertTrue(store.setArchived(false, id: part.id))
            XCTAssertFalse(store.songs[0].isArchived)
            store.deleteSong(song.id)
            XCTAssertTrue(MasteryStore(directory: directory).exercises.isEmpty)
            XCTAssertTrue(MasteryStore(directory: directory).songs.isEmpty)
        }
    }
}
