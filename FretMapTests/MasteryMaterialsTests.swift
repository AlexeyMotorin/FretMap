import XCTest
import UIKit
import UniformTypeIdentifiers
@testable import FretMap

final class MasteryMaterialsTests: XCTestCase {
    #if targetEnvironment(macCatalyst)
    @MainActor func testImageDropWithoutFileURL() async throws {
        let data = try XCTUnwrap(Self.image().pngData())
        let provider = NSItemProvider()
        provider.suggestedName = "Image test"
        provider.registerDataRepresentation(forTypeIdentifier: UTType.png.identifier, visibility: .all) { completion in
            completion(data, nil)
            return nil
        }
        XCTAssertFalse(provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier))
        let file = try await MasteryMaterialReader.droppedFile(from: provider)
        XCTAssertFalse(file.isPDF)
        XCTAssertEqual(file.data, data)
        XCTAssertEqual(file.name, "Image test.png")
        XCTAssertNotNil(UIImage(data: file.data))
    }

    @MainActor func testPDFFileRepresentationIsReadBeforeTemporaryFileDisappears() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("provider-file.tmp")
        let data = Self.pdf()
        try data.write(to: url)
        let provider = NSItemProvider()
        provider.suggestedName = "Song.pdf"
        provider.registerFileRepresentation(forTypeIdentifier: UTType.pdf.identifier, fileOptions: [], visibility: .all) { completion in
            completion(url, false, nil)
            return nil
        }
        XCTAssertFalse(provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier))
        let file = try await MasteryMaterialReader.droppedFile(from: provider)
        XCTAssertTrue(file.isPDF)
        XCTAssertEqual(file.data, data)
        XCTAssertEqual(file.name, "Song.pdf")
    }

    @MainActor func testOversizedDroppedPDFIsRejected() async throws {
        let provider = NSItemProvider()
        let oversized = Data(repeating: 0, count: 5 * 1024 * 1024 + 1)
        provider.registerDataRepresentation(forTypeIdentifier: UTType.pdf.identifier, visibility: .all) { completion in
            completion(oversized, nil)
            return nil
        }
        do {
            _ = try await MasteryMaterialReader.droppedFile(from: provider)
            XCTFail("Oversized PDF must be rejected")
        } catch { XCTAssertTrue(error is PDFImportError) }
    }

    @MainActor func testFileURLDropStillWorksAndWebURLIsRejected() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("Image.png")
        let data = try XCTUnwrap(Self.image().pngData())
        try data.write(to: url)
        let file = try await MasteryMaterialReader.droppedFile(from: NSItemProvider(item: url as NSURL, typeIdentifier: UTType.fileURL.identifier))
        XCTAssertEqual(file.data, data)
        let provider = NSItemProvider(item: try XCTUnwrap(URL(string: "https://example.com")) as NSURL, typeIdentifier: UTType.url.identifier)
        do {
            _ = try await MasteryMaterialReader.droppedFile(from: provider)
            XCTFail("Web addresses must not be imported as files")
        } catch { XCTAssertTrue(error is MasteryMaterialReader.MaterialError) }
    }

    @MainActor func testDraggedFileURLCanBeReadAndUnsupportedFilesAreRejected() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let imageURL = directory.appendingPathComponent("Test.jpg")
        try XCTUnwrap(Self.image().jpegData(compressionQuality: 0.9)).write(to: imageURL)
        let provider = NSItemProvider(item: imageURL as NSURL, typeIdentifier: UTType.fileURL.identifier)
        let droppedURL = await MasteryMaterialReader.droppedURL(from: provider)
        XCTAssertEqual(droppedURL, imageURL)
        let photo = try MasteryMaterialReader.read(XCTUnwrap(droppedURL))
        XCTAssertFalse(photo.isPDF)
        XCTAssertNotNil(UIImage(data: photo.data))
        let pdfURL = directory.appendingPathComponent("Test.pdf")
        try Self.pdf().write(to: pdfURL)
        XCTAssertTrue(try MasteryMaterialReader.read(pdfURL).isPDF)
        try Data(repeating: 0, count: 5 * 1024 * 1024 + 1).write(to: pdfURL)
        XCTAssertThrowsError(try MasteryMaterialReader.read(pdfURL))
        let textURL = directory.appendingPathComponent("Test.txt")
        try Data("text".utf8).write(to: textURL)
        XCTAssertThrowsError(try MasteryMaterialReader.read(textURL))
        let webProvider = NSItemProvider(item: URL(string: "https://example.com")! as NSURL, typeIdentifier: UTType.fileURL.identifier)
        let webURL = await MasteryMaterialReader.droppedURL(from: webProvider)
        XCTAssertNil(webURL)
    }
    #endif

    func testParentMaterialsAreSharedWithExistingAndNewPartsButNeverCopiedBack() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        try await MainActor.run {
            let store = MasteryStore(directory: directory)
            let song = MasterySong(title: "Song", artist: "Artist")
            XCTAssertTrue(store.save(song))
            var part = MasteryExercise(name: "Intro", targetBPM: 120)
            part.songID = song.id
            XCTAssertTrue(store.save(part))
            store.beginEditingSong(song.id)
            store.updateSong(song.id) { $0.materialLinks = ["https://example.com/song"] }
            try store.addSongPhoto(Self.image(), to: song.id)
            let pdf = Self.pdf()
            try store.addSongPDF(data: pdf, name: "Song.pdf", to: song.id)
            XCTAssertEqual(store.inheritedMaterials(for: part.id)?.attachedPhotos.count, 1)
            XCTAssertEqual(store.inheritedMaterials(for: part.id)?.attachedPDFs.count, 1)
            XCTAssertEqual(store.inheritedMaterials(for: part.id)?.materialLinks?.count, 1)
            XCTAssertTrue(store.exercise(part.id)?.photos.isEmpty == true)
            XCTAssertTrue(store.commitSong(song.id))
            var second = MasteryExercise(name: "Verse", targetBPM: 120)
            second.songID = song.id
            XCTAssertTrue(store.save(second))
            XCTAssertEqual(store.inheritedMaterials(for: second.id)?.attachedPhotos.count, 1)
            store.beginEditingExercise(part.id)
            store.update(part.id) { $0.videoLinks = ["https://example.com/part"] }
            store.addPhoto(Self.image(), to: part.id)
            try store.addPDF(data: pdf, name: "Intro.pdf", to: part.id)
            XCTAssertTrue(store.commitExercise(part.id))
            XCTAssertEqual(store.song(song.id)?.attachedPhotos.count, 1)
            XCTAssertEqual(store.song(song.id)?.attachedPDFs.first?.name, "Song.pdf")
            XCTAssertEqual(store.song(song.id)?.materialLinks, ["https://example.com/song"])
            XCTAssertTrue(store.exercise(second.id)?.photos.isEmpty == true)
            let independent = MasteryExercise(name: "Independent", targetBPM: 120)
            XCTAssertTrue(store.save(independent))
            XCTAssertNil(store.inheritedMaterials(for: independent.id))
        }
    }

    func testSongPhotoDraftDiscardAndRemovalPreserveSavedFiles() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        try await MainActor.run {
            let store = MasteryStore(directory: directory)
            let song = MasterySong(title: "Song", artist: "Artist")
            XCTAssertTrue(store.save(song))
            store.beginEditingSong(song.id)
            try store.addSongPhoto(Self.image(), to: song.id)
            let discarded = try XCTUnwrap(store.song(song.id)?.attachedPhotos.first)
            XCTAssertTrue(store.hasUnsavedSongChanges(song.id))
            XCTAssertTrue(MasteryStore(directory: directory).song(song.id)?.attachedPhotos.isEmpty == true)
            store.discardSongChanges(song.id)
            XCTAssertFalse(FileManager.default.fileExists(atPath: store.photoURL(discarded).path))
            try store.addSongPhoto(Self.image(), to: song.id)
            let saved = try XCTUnwrap(store.song(song.id)?.attachedPhotos.first)
            store.beginEditingSong(song.id)
            store.removeSongPhoto(saved, from: song.id)
            XCTAssertTrue(FileManager.default.fileExists(atPath: store.photoURL(saved).path))
            store.discardSongChanges(song.id)
            XCTAssertEqual(store.song(song.id)?.attachedPhotos, [saved])
            store.beginEditingSong(song.id)
            store.removeSongPhoto(saved, from: song.id)
            XCTAssertTrue(store.commitSong(song.id))
            XCTAssertFalse(FileManager.default.fileExists(atPath: store.photoURL(saved).path))
        }
    }

    func testSongImagesSurviveBackupAndPhotoLimitIsEnforced() async throws {
        let source = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let destination = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: source); try? FileManager.default.removeItem(at: destination) }
        try await MainActor.run {
            let store = MasteryStore(directory: source)
            let song = MasterySong(title: "Song", artist: "Artist")
            XCTAssertTrue(store.save(song))
            for _ in 0..<3 { try store.addSongPhoto(Self.image(), to: song.id) }
            XCTAssertThrowsError(try store.addSongPhoto(Self.image(), to: song.id))
            try store.addSongPDF(data: Self.pdf(), name: "Song.pdf", to: song.id)
            XCTAssertThrowsError(try store.addSongPDF(data: Self.pdf(), name: "Second.pdf", to: song.id))
            let backup = try store.makeBackup(settings: Data())
            try backup.validate()
            XCTAssertEqual(backup.photos.count, 3)
            XCTAssertEqual(backup.documents?.count, 1)
            let restored = MasteryStore(directory: destination)
            try restored.restoreBackup(backup)
            XCTAssertEqual(restored.song(song.id)?.attachedPhotos.count, 3)
            for photo in restored.song(song.id)?.attachedPhotos ?? [] {
                XCTAssertNotNil(UIImage(contentsOfFile: restored.photoURL(photo).path))
            }
            XCTAssertEqual(restored.song(song.id)?.attachedPDFs.count, 1)
        }
    }

    func testOldSongsDecodeWithoutPhotoField() throws {
        let song = MasterySong(title: "Old", artist: "Artist")
        let data = try JSONEncoder().encode(song)
        var object = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        object.removeValue(forKey: "photos")
        let restored = try JSONDecoder().decode(MasterySong.self, from: JSONSerialization.data(withJSONObject: object))
        XCTAssertTrue(restored.attachedPhotos.isEmpty)
    }

    @MainActor private static func image() -> UIImage {
        UIGraphicsImageRenderer(size: CGSize(width: 20, height: 20)).image { context in
            UIColor.blue.setFill(); context.fill(CGRect(x: 0, y: 0, width: 20, height: 20))
        }
    }
    @MainActor private static func pdf() -> Data {
        UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 100, height: 100)).pdfData { $0.beginPage() }
    }
}
