import PDFKit
import Combine
import Foundation
import SwiftUI

nonisolated enum PracticeSubdivision: String, Codable, CaseIterable, Sendable {
    case quarters, eighths, triplets, sixteenths, sextuplets, thirtySeconds
    var notesPerBeat: Int {
        switch self {
        case .quarters: 1
        case .eighths: 2
        case .triplets: 3
        case .sixteenths: 4
        case .sextuplets: 6
        case .thirtySeconds: 8
        }
    }
    var beamCount: Int {
        switch self {
        case .quarters: 0
        case .eighths, .triplets: 1
        case .sixteenths, .sextuplets: 2
        case .thirtySeconds: 3
        }
    }
    var tupletNumber: Int? {
        switch self {
        case .triplets: 3
        case .sextuplets: 6
        default: nil
        }
    }
    var localizationKey: String { "mastery.subdivision." + rawValue }
}

nonisolated struct MasteryResult: Identifiable, Codable, Sendable {
    var id = UUID()
    var date = Date()
    var bpm: Int
    var clean: Bool
    var note: String
    var subdivision: PracticeSubdivision? = nil
    var cleanRepetitions: Int? = nil
    var difficulty: ExerciseDifficulty? = nil
}

nonisolated struct MasterySession: Identifiable, Codable, Sendable {
    var id = UUID()
    var date = Date()
    var seconds: TimeInterval
}

nonisolated struct MasteryPDF: Identifiable, Codable, Sendable {
    var id: String
    var name: String
}

nonisolated enum ExerciseDifficulty: String, Codable, CaseIterable, Sendable {
    case hard, medium, easy
    var localizationKey: String { "mastery.difficulty." + rawValue }
}

nonisolated struct MasteryExercise: Identifiable, Codable, Sendable {
    var id = UUID()
    var name: String
    var targetBPM: Int
    var subdivision: PracticeSubdivision? = nil
    var category: String = ""
    var comment: String = ""
    var videoLinks: [String]? = nil
    var linkTitles: [String: String]? = nil
    var photos: [String] = []
    var pdfs: [MasteryPDF]? = nil
    var attachedPDFs: [MasteryPDF] { pdfs ?? [] }
    var results: [MasteryResult] = []
    var sessions: [MasterySession] = []
    var difficulty: ExerciseDifficulty? = nil
    var completedAt: Date? = nil
    var isArchived: Bool { completedAt != nil }
    var createdAt = Date()

    var hasValidVideoLinks: Bool {
        let links = videoLinks ?? []
        return Set(links).count == links.count && links.allSatisfy {
            guard let url = URL(string: $0), let host = url.host, !host.isEmpty else { return false }
            return ["http", "https"].contains(url.scheme?.lowercased() ?? "")
        }
    }
    var latest: MasteryResult? { results.max { $0.date < $1.date } }
    var bestCleanBPM: Int? { results.filter(\.clean).map(\.bpm).max() }
    var progress: Double { min(1, Double(bestCleanBPM ?? 0) / Double(max(1, targetBPM))) }
    var practiceSeconds: TimeInterval { sessions.reduce(0) { $0 + $1.seconds } }
}

@MainActor
final class MasteryStore: ObservableObject {
    @Published private(set) var exercises: [MasteryExercise] = []
    @Published var error: String?
    private let directory: URL
    private var canWrite = true
    private var dataURL: URL { directory.appendingPathComponent("exercises.json") }

    init(directory: URL? = nil) {
        self.directory = directory ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("MasteryPath", isDirectory: true)
        do {
            try FileManager.default.createDirectory(at: self.directory, withIntermediateDirectories: true)
            if FileManager.default.fileExists(atPath: dataURL.path) {
                exercises = try JSONDecoder().decode([MasteryExercise].self, from: Data(contentsOf: dataURL))
            }
        } catch {
            canWrite = false
            self.error = L10n.string("mastery.load.error")
        }
    }

    var categories: [String] { Array(Set(exercises.map(\.category).filter { !$0.isEmpty })).sorted() }

    @discardableResult
    func save(_ exercise: MasteryExercise) -> Bool {
        guard !exercise.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              (20...400).contains(exercise.targetBPM),
              exercise.hasValidVideoLinks,
              exercise.results.allSatisfy({ (20...400).contains($0.bpm) && ($0.cleanRepetitions == nil || ($0.clean && (1...100).contains($0.cleanRepetitions ?? 0))) }),
              exercise.sessions.allSatisfy({ $0.seconds.isFinite && $0.seconds >= 0 }) else {
            error = L10n.string("mastery.validation")
            return false
        }
        var next = exercises
        if let index = next.firstIndex(where: { $0.id == exercise.id }) { next[index] = exercise }
        else { next.insert(exercise, at: 0) }
        return persist(next)
    }

    func update(_ id: UUID, _ change: (inout MasteryExercise) -> Void) {
        guard var exercise = exercises.first(where: { $0.id == id }) else { return }
        change(&exercise)
        save(exercise)
    }

    @discardableResult
    func setArchived(_ archived: Bool, id: UUID) -> Bool {
        guard var exercise = exercises.first(where: { $0.id == id }) else { return false }
        exercise.completedAt = archived ? (exercise.completedAt ?? Date()) : nil
        return save(exercise)
    }

    func delete(_ id: UUID) {
        guard let exercise = exercises.first(where: { $0.id == id }) else { return }
        if persist(exercises.filter { $0.id != id }) {
            for name in exercise.photos + exercise.attachedPDFs.map(\.id) { try? FileManager.default.removeItem(at: photoURL(name)) }
        }
    }

    func makeBackup(settings: Data) throws -> FretMapBackup {
        guard canWrite else { throw BackupError.invalid }
        var photos: [String: Data] = [:]
        var total = 0
        for name in Set(exercises.flatMap(\.photos)) {
            let data = try Data(contentsOf: photoURL(name))
            total += data.count
            guard total <= 70 * 1024 * 1024 else { throw BackupError.tooLarge }
            photos[name] = data
        }
        var documents: [String: Data] = [:]
        for name in Set(exercises.flatMap { $0.attachedPDFs.map(\.id) }) {
            let data = try Data(contentsOf: photoURL(name))
            total += data.count
            guard total <= 70 * 1024 * 1024 else { throw BackupError.tooLarge }
            documents[name] = data
        }
        return FretMapBackup(settings: settings, exercises: exercises, photos: photos, documents: documents)
    }

    func restoreBackup(_ backup: FretMapBackup) throws {
        try backup.validate()
        var created: [URL] = []
        let oldPhotos = Set(exercises.flatMap { $0.photos + $0.attachedPDFs.map(\.id) })
        let oldCanWrite = canWrite
        var committed = false
        defer {
            if !committed {
                canWrite = oldCanWrite
                for url in created { try? FileManager.default.removeItem(at: url) }
            }
        }
        var names: [String: String] = [:]
        for original in Set(backup.exercises.flatMap(\.photos)) {
            guard let data = backup.photos[original] else { throw BackupError.invalid }
            let name = UUID().uuidString + ".jpg"
            let url = photoURL(name)
            try data.write(to: url, options: .atomic)
            created.append(url)
            names[original] = name
        }
        var pdfNames: [String: String] = [:]
        for original in Set(backup.exercises.flatMap { $0.attachedPDFs.map(\.id) }) {
            guard let data = backup.documents?[original] else { throw BackupError.invalid }
            let name = UUID().uuidString + ".pdf"
            let url = photoURL(name)
            try data.write(to: url, options: .atomic)
            created.append(url)
            pdfNames[original] = name
        }
        var restored = backup.exercises
        for index in restored.indices {
            restored[index].photos = restored[index].photos.compactMap { names[$0] }
            restored[index].pdfs = restored[index].attachedPDFs.compactMap { pdf in
                pdfNames[pdf.id].map { MasteryPDF(id: $0, name: pdf.name) }
            }
        }
        canWrite = true
        guard persist(restored) else { throw BackupError.storage }
        committed = true
        error = nil
        for name in oldPhotos { try? FileManager.default.removeItem(at: photoURL(name)) }
    }

    private func persist(_ next: [MasteryExercise]) -> Bool {
        guard canWrite else { error = L10n.string("mastery.load.error"); return false }
        do {
            try JSONEncoder().encode(next).write(to: dataURL, options: .atomic)
            exercises = next
            return true
        } catch {
            self.error = L10n.string("mastery.save.error")
            return false
        }
    }

    func photoURL(_ name: String) -> URL { directory.appendingPathComponent(name) }

    func addPhoto(_ image: UIImage, to id: UUID) {
        guard var exercise = exercises.first(where: { $0.id == id }), exercise.photos.count < 3 else { return }
        let ratio = min(1, 2400 / max(image.size.width, image.size.height))
        let size = CGSize(width: max(1, image.size.width * ratio), height: max(1, image.size.height * ratio))
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let resized = UIGraphicsImageRenderer(size: size, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
        guard let data = resized.jpegData(compressionQuality: 0.9) else { error = L10n.string("mastery.photo.error"); return }
        let name = UUID().uuidString + ".jpg"
        do {
            try data.write(to: photoURL(name), options: .atomic)
            exercise.photos.append(name)
            if !save(exercise) { try? FileManager.default.removeItem(at: photoURL(name)) }
        } catch { self.error = L10n.string("mastery.photo.error") }
    }

    func addPDF(data: Data, name: String, to id: UUID) throws {
        guard data.count <= 5 * 1024 * 1024,
              let document = PDFDocument(data: data), !document.isLocked, document.pageCount > 0,
              var exercise = exercises.first(where: { $0.id == id }), exercise.attachedPDFs.isEmpty
        else { throw PDFImportError.invalid }
        let filename = UUID().uuidString + ".pdf"
        try data.write(to: photoURL(filename), options: .atomic)
        exercise.pdfs = exercise.attachedPDFs + [MasteryPDF(id: filename, name: name)]
        if !save(exercise) {
            try? FileManager.default.removeItem(at: photoURL(filename))
            throw BackupError.storage
        }
    }

    func removePDF(_ id: String, from exerciseID: UUID) {
        guard var exercise = exercises.first(where: { $0.id == exerciseID }) else { return }
        exercise.pdfs = exercise.attachedPDFs.filter { $0.id != id }
        if save(exercise) { try? FileManager.default.removeItem(at: photoURL(id)) }
    }

    func removePhoto(_ name: String, from id: UUID) {
        guard var exercise = exercises.first(where: { $0.id == id }) else { return }
        exercise.photos.removeAll { $0 == name }
        if save(exercise) { try? FileManager.default.removeItem(at: photoURL(name)) }
    }
}
