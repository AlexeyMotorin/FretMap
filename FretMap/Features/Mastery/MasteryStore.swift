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

nonisolated struct MasteryResult: Identifiable, Codable, Sendable, Equatable {
    var id = UUID()
    var date = Date()
    var bpm: Int
    var clean: Bool
    var note: String
    var subdivision: PracticeSubdivision? = nil
    var cleanRepetitions: Int? = nil
    var difficulty: ExerciseDifficulty? = nil
}

nonisolated struct MasterySession: Identifiable, Codable, Sendable, Equatable {
    var id = UUID()
    var date = Date()
    var seconds: TimeInterval
}

nonisolated struct MasteryPDF: Identifiable, Codable, Sendable, Equatable {
    var id: String
    var name: String
}

nonisolated enum ExerciseDifficulty: String, Codable, CaseIterable, Sendable {
    case hard, medium, easy
    var localizationKey: String { "mastery.difficulty." + rawValue }
}

nonisolated struct MasteryExercise: Identifiable, Codable, Sendable, Equatable {
    var id = UUID()
    var name: String
    var manualOrder: Int? = nil
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
    /// `nil` keeps the exercise in the independent Exercises workspace.
    var songID: UUID? = nil
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

nonisolated struct MasterySong: Identifiable, Codable, Sendable, Equatable {
    var id = UUID()
    var title: String
    var artist: String
    var manualOrder: Int? = nil
    var archivedAt: Date? = nil
    var createdAt = Date()
    var materialLinks: [String]? = nil
    var materialLinkTitles: [String: String]? = nil
    var pdfs: [MasteryPDF]? = nil
    var photos: [String]? = nil

    var isArchived: Bool { archivedAt != nil }
    var attachedPDFs: [MasteryPDF] { pdfs ?? [] }
    var attachedPhotos: [String] { photos ?? [] }
    var hasValidMaterialLinks: Bool {
        let links = materialLinks ?? []
        return Set(links).count == links.count && links.allSatisfy {
            guard let url = URL(string: $0), let host = url.host, !host.isEmpty else { return false }
            return ["http", "https"].contains(url.scheme?.lowercased() ?? "")
        }
    }

    enum CodingKeys: String, CodingKey { case id, title, artist, archivedAt, createdAt, materialLinks, materialLinkTitles, pdfs, photos, manualOrder }
    init(id: UUID = UUID(), title: String, artist: String, archivedAt: Date? = nil, createdAt: Date = Date(), materialLinks: [String]? = nil, materialLinkTitles: [String: String]? = nil, pdfs: [MasteryPDF]? = nil, photos: [String]? = nil) {
        self.id = id; self.title = title; self.artist = artist; self.archivedAt = archivedAt; self.createdAt = createdAt
        self.materialLinks = materialLinks; self.materialLinkTitles = materialLinkTitles; self.pdfs = pdfs
        self.photos = photos
    }
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        title = try values.decode(String.self, forKey: .title)
        artist = try values.decode(String.self, forKey: .artist)
        manualOrder = try values.decodeIfPresent(Int.self, forKey: .manualOrder)
        archivedAt = try values.decodeIfPresent(Date.self, forKey: .archivedAt)
        createdAt = try values.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        materialLinks = try values.decodeIfPresent([String].self, forKey: .materialLinks)
        materialLinkTitles = try values.decodeIfPresent([String: String].self, forKey: .materialLinkTitles)
        photos = try values.decodeIfPresent([String].self, forKey: .photos)
        pdfs = try values.decodeIfPresent([MasteryPDF].self, forKey: .pdfs)
    }
}

@MainActor
final class MasteryStore: ObservableObject {
    private struct Snapshot: Codable {
        var exercises: [MasteryExercise]
        var songs: [MasterySong]
    }
    @Published private(set) var exercises: [MasteryExercise] = []
    @Published private(set) var songs: [MasterySong] = []
    @Published private var exerciseDrafts: [UUID: MasteryExercise] = [:]
    @Published private var songDrafts: [UUID: MasterySong] = [:]
    @Published var error: String?
    private let directory: URL
    private var canWrite = true
    private var dataURL: URL { directory.appendingPathComponent("exercises.json") }
    private var songsURL: URL { directory.appendingPathComponent("songs.json") }
    private var snapshotURL: URL { directory.appendingPathComponent("mastery.json") }

    init(directory: URL? = nil) {
        self.directory = directory ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("MasteryPath", isDirectory: true)
        do {
            try FileManager.default.createDirectory(at: self.directory, withIntermediateDirectories: true)
            if FileManager.default.fileExists(atPath: snapshotURL.path) {
                let snapshot = try JSONDecoder().decode(Snapshot.self, from: Data(contentsOf: snapshotURL))
                exercises = snapshot.exercises
                songs = snapshot.songs
                return
            }
            if FileManager.default.fileExists(atPath: dataURL.path) {
                exercises = try JSONDecoder().decode([MasteryExercise].self, from: Data(contentsOf: dataURL))
            }
            if FileManager.default.fileExists(atPath: songsURL.path) {
                songs = try JSONDecoder().decode([MasterySong].self, from: Data(contentsOf: songsURL))
            }
        } catch {
            canWrite = false
            self.error = L10n.string("mastery.load.error")
        }
    }

    var categories: [String] { Array(Set(exercises.filter { $0.songID == nil }.map(\.category).filter { !$0.isEmpty })).sorted() }

    func exercise(_ id: UUID) -> MasteryExercise? { exerciseDrafts[id] ?? exercises.first { $0.id == id } }
    func song(_ id: UUID) -> MasterySong? { songDrafts[id] ?? songs.first { $0.id == id } }
    /// Parent materials are shared, never copied into a part's own attachments.
    func inheritedMaterials(for exerciseID: UUID) -> MasterySong? {
        exercise(exerciseID)?.songID.flatMap { song($0) }
    }
    func beginEditingExercise(_ id: UUID) { if exerciseDrafts[id] == nil, let value = exercises.first(where: { $0.id == id }) { exerciseDrafts[id] = value } }
    func beginEditingSong(_ id: UUID) { if songDrafts[id] == nil, let value = songs.first(where: { $0.id == id }) { songDrafts[id] = value } }
    func hasUnsavedExerciseChanges(_ id: UUID) -> Bool {
        guard let draft = exerciseDrafts[id], let saved = exercises.first(where: { $0.id == id }) else { return false }
        return draft != saved
    }
    func hasUnsavedSongChanges(_ id: UUID) -> Bool {
        guard let draft = songDrafts[id], let saved = songs.first(where: { $0.id == id }) else { return false }
        return draft != saved
    }

    @discardableResult
    func commitExercise(_ id: UUID) -> Bool {
        guard let draft = exerciseDrafts[id] else { return true }
        exerciseDrafts[id] = nil
        guard save(draft) else { exerciseDrafts[id] = draft; return false }
        return true
    }

    @discardableResult
    func commitSong(_ id: UUID) -> Bool {
        guard let draft = songDrafts[id] else { return true }
        songDrafts[id] = nil
        guard save(draft) else { songDrafts[id] = draft; return false }
        return true
    }

    func discardExerciseChanges(_ id: UUID) {
        guard let draft = exerciseDrafts.removeValue(forKey: id), let saved = exercises.first(where: { $0.id == id }) else { return }
        let removed = Set(draft.photos + draft.attachedPDFs.map(\.id)).subtracting(saved.photos + saved.attachedPDFs.map(\.id))
        for name in removed { try? FileManager.default.removeItem(at: photoURL(name)) }
    }

    func discardSongChanges(_ id: UUID) {
        guard let draft = songDrafts.removeValue(forKey: id), let saved = songs.first(where: { $0.id == id }) else { return }
        for file in Set(draft.attachedPhotos + draft.attachedPDFs.map(\.id)).subtracting(saved.attachedPhotos + saved.attachedPDFs.map(\.id)) { try? FileManager.default.removeItem(at: photoURL(file)) }
    }

    func parts(for songID: UUID) -> [MasteryExercise] {
        exercises.filter { $0.songID == songID }.sorted { $0.createdAt < $1.createdAt }
    }

    func isLearned(_ song: MasterySong) -> Bool {
        let parts = parts(for: song.id)
        return !parts.isEmpty && parts.allSatisfy(\.isArchived)
    }

    @discardableResult
    func save(_ song: MasterySong) -> Bool {
        guard !song.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !song.artist.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              song.hasValidMaterialLinks else {
            error = L10n.string("song.validation")
            return false
        }
        if songDrafts[song.id] != nil { songDrafts[song.id] = song; return true }
        var next = songs
        if let index = next.firstIndex(where: { $0.id == song.id }) { next[index] = song }
        else { next.insert(song, at: 0) }
        return persistSongs(next)
    }

    @discardableResult
    func setSongArchived(_ archived: Bool, id: UUID) -> Bool {
        guard var song = song(id), !archived || isLearned(song) else { return false }
        song.archivedAt = archived ? (song.archivedAt ?? Date()) : nil
        return save(song)
    }

    func deleteSong(_ id: UUID) {
        let partsToDelete = parts(for: id)
        let songToDelete = songs.first(where: { $0.id == id })
        guard persistSnapshot(exercises.filter { $0.songID != id }, songs: songs.filter { $0.id != id }) else { return }
        discardSongChanges(id)
        for part in partsToDelete { exerciseDrafts[part.id] = nil }
        for part in partsToDelete {
            for name in part.photos + part.attachedPDFs.map(\.id) { try? FileManager.default.removeItem(at: photoURL(name)) }
        }
        for file in (songToDelete?.attachedPhotos ?? []) + (songToDelete?.attachedPDFs.map(\.id) ?? []) { try? FileManager.default.removeItem(at: photoURL(file)) }
    }

    func updateSong(_ id: UUID, _ change: (inout MasterySong) -> Void) {
        guard var song = song(id) else { return }
        change(&song)
        save(song)
    }

    func addSongPDF(data: Data, name: String, to songID: UUID) throws {
        guard data.count <= 5 * 1024 * 1024,
              let document = PDFDocument(data: data), !document.isLocked, document.pageCount > 0,
              var song = song(songID), song.attachedPDFs.isEmpty
        else { throw PDFImportError.invalid }
        let filename = UUID().uuidString + ".pdf"
        try data.write(to: photoURL(filename), options: .atomic)
        song.pdfs = song.attachedPDFs + [MasteryPDF(id: filename, name: name)]
        if !save(song) { try? FileManager.default.removeItem(at: photoURL(filename)); throw BackupError.storage }
    }

    func removeSongPDF(_ id: String, from songID: UUID) {
        guard var song = song(songID) else { return }
        song.pdfs = song.attachedPDFs.filter { $0.id != id }
        if save(song), !(songs.first { $0.id == songID }?.attachedPDFs.contains { $0.id == id } ?? false) {
            try? FileManager.default.removeItem(at: photoURL(id))
        }
    }

    @discardableResult
    func save(_ exercise: MasteryExercise) -> Bool {
        guard !exercise.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              exercise.songID == nil || songs.contains(where: { $0.id == exercise.songID }),
              (20...400).contains(exercise.targetBPM),
              exercise.hasValidVideoLinks,
              exercise.results.allSatisfy({ (20...400).contains($0.bpm) && ($0.cleanRepetitions == nil || ($0.clean && (1...100).contains($0.cleanRepetitions ?? 0))) }),
              exercise.sessions.allSatisfy({ $0.seconds.isFinite && $0.seconds >= 0 }) else {
            error = L10n.string("mastery.validation")
            return false
        }
        if exerciseDrafts[exercise.id] != nil { exerciseDrafts[exercise.id] = exercise; return true }
        var next = exercises
        if let index = next.firstIndex(where: { $0.id == exercise.id }) { next[index] = exercise }
        else { next.insert(exercise, at: 0) }
        return persist(next)
    }

    func update(_ id: UUID, _ change: (inout MasteryExercise) -> Void) {
        guard var exercise = exercise(id) else { return }
        change(&exercise)
        save(exercise)
    }

    @discardableResult
    func setArchived(_ archived: Bool, id: UUID) -> Bool {
        guard var exercise = exercise(id) else { return false }
        exercise.completedAt = archived ? (exercise.completedAt ?? Date()) : nil
        return save(exercise)
    }

    func delete(_ id: UUID) {
        guard let exercise = exercises.first(where: { $0.id == id }) else { return }
        if persist(exercises.filter { $0.id != id }) {
            exerciseDrafts[id] = nil
            for name in exercise.photos + exercise.attachedPDFs.map(\.id) { try? FileManager.default.removeItem(at: photoURL(name)) }
        }
    }

    func makeBackup(settings: Data) throws -> FretMapBackup {
        guard canWrite else { throw BackupError.invalid }
        var photos: [String: Data] = [:]
        var total = 0
        for name in Set(exercises.flatMap(\.photos) + songs.flatMap(\.attachedPhotos)) {
            let data = try Data(contentsOf: photoURL(name))
            total += data.count
            guard total <= 70 * 1024 * 1024 else { throw BackupError.tooLarge }
            photos[name] = data
        }
        var documents: [String: Data] = [:]
        for name in Set(exercises.flatMap { $0.attachedPDFs.map(\.id) } + songs.flatMap { $0.attachedPDFs.map(\.id) }) {
            let data = try Data(contentsOf: photoURL(name))
            total += data.count
            guard total <= 70 * 1024 * 1024 else { throw BackupError.tooLarge }
            documents[name] = data
        }
        return FretMapBackup(settings: settings, exercises: exercises, songs: songs, photos: photos, documents: documents)
    }

    func restoreBackup(_ backup: FretMapBackup) throws {
        try backup.validate()
        var created: [URL] = []
        let oldPhotos = Set(exercises.flatMap { $0.photos + $0.attachedPDFs.map(\.id) } + songs.flatMap { $0.attachedPhotos + $0.attachedPDFs.map(\.id) })
        let oldCanWrite = canWrite
        var committed = false
        defer {
            if !committed {
                canWrite = oldCanWrite
                for url in created { try? FileManager.default.removeItem(at: url) }
            }
        }
        var names: [String: String] = [:]
        for original in Set(backup.exercises.flatMap(\.photos) + backup.songs.flatMap(\.attachedPhotos)) {
            guard let data = backup.photos[original] else { throw BackupError.invalid }
            let name = UUID().uuidString + ".jpg"
            let url = photoURL(name)
            try data.write(to: url, options: .atomic)
            created.append(url)
            names[original] = name
        }
        var pdfNames: [String: String] = [:]
        for original in Set(backup.exercises.flatMap { $0.attachedPDFs.map(\.id) } + backup.songs.flatMap { $0.attachedPDFs.map(\.id) }) {
            guard let data = backup.documents?[original] else { throw BackupError.invalid }
            let name = UUID().uuidString + ".pdf"
            let url = photoURL(name)
            try data.write(to: url, options: .atomic)
            created.append(url)
            pdfNames[original] = name
        }
        var restored = backup.exercises
        var restoredSongs = backup.songs
        for index in restored.indices {
            restored[index].photos = restored[index].photos.compactMap { names[$0] }
            restored[index].pdfs = restored[index].attachedPDFs.compactMap { pdf in
                pdfNames[pdf.id].map { MasteryPDF(id: $0, name: pdf.name) }
            }
        }
        for index in restoredSongs.indices {
            restoredSongs[index].photos = restoredSongs[index].attachedPhotos.compactMap { names[$0] }
            restoredSongs[index].pdfs = restoredSongs[index].attachedPDFs.compactMap { pdf in
                pdfNames[pdf.id].map { MasteryPDF(id: $0, name: pdf.name) }
            }
        }
        canWrite = true
        guard persistSnapshot(restored, songs: restoredSongs) else { throw BackupError.storage }
        exerciseDrafts = [:]
        songDrafts = [:]
        committed = true
        error = nil
        for name in oldPhotos { try? FileManager.default.removeItem(at: photoURL(name)) }
    }

    /// Reorder only the displayed subset; hidden items keep their relative order.
    @discardableResult
    func reorder(_ source: UUID, before target: UUID, visibleIDs: [UUID], songs: Bool) -> Bool {
        guard source != target, Set(visibleIDs).count == visibleIDs.count,
              let destination = visibleIDs.firstIndex(of: target), visibleIDs.contains(source) else { return false }
        var ids = visibleIDs.filter { $0 != source }
        ids.insert(source, at: min(destination, ids.count))
        func ranks(in all: [UUID]) -> [UUID: Int] {
            guard Set(visibleIDs).isSubset(of: Set(all)) else { return [:] }
            var remaining = ids.makeIterator()
            let visible = Set(visibleIDs)
            let ordered = all.map { visible.contains($0) ? remaining.next()! : $0 }
            return Dictionary(uniqueKeysWithValues: ordered.enumerated().map { ($0.element, $0.offset) })
        }
        if songs {
            var next = self.songs
            let ranks = ranks(in: next.sorted {
                if $0.manualOrder != $1.manualOrder { return ($0.manualOrder ?? -1) < ($1.manualOrder ?? -1) }
                return $0.createdAt > $1.createdAt
            }.map(\.id))
            guard !ranks.isEmpty else { return false }
            for index in next.indices {
                if let rank = ranks[next[index].id] { next[index].manualOrder = rank }
            }
            return persistSongs(next)
        } else {
            var next = exercises
            let ranks = ranks(in: next.sorted {
                if $0.manualOrder != $1.manualOrder { return ($0.manualOrder ?? -1) < ($1.manualOrder ?? -1) }
                return $0.createdAt > $1.createdAt
            }.map(\.id))
            guard !ranks.isEmpty else { return false }
            for index in next.indices {
                if let rank = ranks[next[index].id] { next[index].manualOrder = rank }
            }
            return persist(next)
        }
    }

    private func persist(_ next: [MasteryExercise]) -> Bool {
        persistSnapshot(next, songs: songs)
    }

    private func persistSongs(_ next: [MasterySong]) -> Bool {
        persistSnapshot(exercises, songs: next)
    }

    /// Commit both collections together so deletion and backup restore cannot leave orphaned parts.
    private func persistSnapshot(_ nextExercises: [MasteryExercise], songs nextSongs: [MasterySong]) -> Bool {
        guard canWrite else { error = L10n.string("mastery.load.error"); return false }
        var nextSongs = nextSongs
        for index in nextSongs.indices where nextSongs[index].isArchived {
            let parts = nextExercises.filter { $0.songID == nextSongs[index].id }
            if parts.isEmpty || !parts.allSatisfy(\.isArchived) {
                nextSongs[index].archivedAt = nil
                songDrafts[nextSongs[index].id]?.archivedAt = nil
            }
        }
        do {
            try JSONEncoder().encode(Snapshot(exercises: nextExercises, songs: nextSongs)).write(to: snapshotURL, options: .atomic)
            let oldFiles = Set(exercises.flatMap { $0.photos + $0.attachedPDFs.map(\.id) } + songs.flatMap { $0.attachedPhotos + $0.attachedPDFs.map(\.id) })
            let newFiles = Set(nextExercises.flatMap { $0.photos + $0.attachedPDFs.map(\.id) } + nextSongs.flatMap { $0.attachedPhotos + $0.attachedPDFs.map(\.id) })
            exercises = nextExercises
            songs = nextSongs
            for name in oldFiles.subtracting(newFiles) { try? FileManager.default.removeItem(at: photoURL(name)) }
            return true
        } catch {
            self.error = L10n.string("mastery.save.error")
            return false
        }
    }

    func photoURL(_ name: String) -> URL { directory.appendingPathComponent(name) }

    func addSongPhoto(_ image: UIImage, to id: UUID) throws {
        guard var song = song(id), song.attachedPhotos.count < 3 else { throw BackupError.invalid }
        let data = try preparedPhotoData(image)
        let name = UUID().uuidString + ".jpg"
        try data.write(to: photoURL(name), options: .atomic)
        song.photos = song.attachedPhotos + [name]
        if !save(song) {
            try? FileManager.default.removeItem(at: photoURL(name))
            throw BackupError.storage
        }
    }

    func removeSongPhoto(_ name: String, from id: UUID) {
        guard var song = song(id) else { return }
        song.photos = song.attachedPhotos.filter { $0 != name }
        if save(song), !(songs.first { $0.id == id }?.attachedPhotos.contains(name) ?? false) {
            try? FileManager.default.removeItem(at: photoURL(name))
        }
    }

    func addPhoto(_ image: UIImage, to id: UUID) {
        guard var exercise = exercise(id), exercise.photos.count < 3 else { return }
        let name = UUID().uuidString + ".jpg"
        do {
            let data = try preparedPhotoData(image)
            try data.write(to: photoURL(name), options: .atomic)
            exercise.photos.append(name)
            if !save(exercise) { try? FileManager.default.removeItem(at: photoURL(name)) }
        } catch { self.error = L10n.string("mastery.photo.error") }
    }

    private func preparedPhotoData(_ image: UIImage) throws -> Data {
        let ratio = min(1, 2400 / max(image.size.width, image.size.height))
        let size = CGSize(width: max(1, image.size.width * ratio), height: max(1, image.size.height * ratio))
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let resized = UIGraphicsImageRenderer(size: size, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
        guard let data = resized.jpegData(compressionQuality: 0.9) else { throw BackupError.invalid }
        return data
    }

    func addPDF(data: Data, name: String, to id: UUID) throws {
        guard data.count <= 5 * 1024 * 1024,
              let document = PDFDocument(data: data), !document.isLocked, document.pageCount > 0,
              var exercise = exercise(id), exercise.attachedPDFs.isEmpty
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
        guard var exercise = exercise(exerciseID) else { return }
        exercise.pdfs = exercise.attachedPDFs.filter { $0.id != id }
        if save(exercise), !(exercises.first { $0.id == exerciseID }?.attachedPDFs.contains { $0.id == id } ?? false) {
            try? FileManager.default.removeItem(at: photoURL(id))
        }
    }

    func removePhoto(_ name: String, from id: UUID) {
        guard var exercise = exercise(id) else { return }
        exercise.photos.removeAll { $0 == name }
        if save(exercise), !(exercises.first { $0.id == id }?.photos.contains(name) ?? false) {
            try? FileManager.default.removeItem(at: photoURL(name))
        }
    }
}
