import SwiftUI
import PDFKit
import UniformTypeIdentifiers

nonisolated struct FretMapBackup: Codable, Sendable {
    var format = "FretMapBackup"
    var version = 2
    var createdAt = Date()
    let settings: Data
    let exercises: [MasteryExercise]
    let photos: [String: Data]
    var documents: [String: Data]? = nil

    func validate() throws {
        guard format == "FretMapBackup", (1...2).contains(version),
              Set(exercises.map(\.id)).count == exercises.count,
              exercises.allSatisfy({ exercise in
                  !exercise.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                  (20...400).contains(exercise.targetBPM) && exercise.photos.count <= 8 &&
                  Set(exercise.results.map(\.id)).count == exercise.results.count &&
                  Set(exercise.sessions.map(\.id)).count == exercise.sessions.count &&
                  exercise.results.allSatisfy { (20...400).contains($0.bpm) } &&
                  exercise.sessions.allSatisfy { $0.seconds.isFinite && $0.seconds >= 0 } &&
                  exercise.photos.allSatisfy { photos[$0] != nil } &&
                  exercise.attachedPDFs.count <= 8 &&
                  Set(exercise.attachedPDFs.map(\.id)).count == exercise.attachedPDFs.count &&
                  exercise.attachedPDFs.allSatisfy { documents?[$0.id] != nil }
              }),
              photos.allSatisfy({ name, data in
                  name == URL(fileURLWithPath: name).lastPathComponent && !name.hasPrefix(".") &&
                  name.hasSuffix(".jpg") && UIImage(data: data) != nil
              }),
              (documents ?? [:]).allSatisfy({ name, data in
                  guard name == URL(fileURLWithPath: name).lastPathComponent,
                        !name.hasPrefix("."), name.hasSuffix(".pdf"), data.count <= 20 * 1024 * 1024,
                        let document = PDFDocument(data: data) else { return false }
                  return !document.isLocked && document.pageCount > 0
              }) else { throw BackupError.invalid }
    }
}

enum BackupError: LocalizedError {
    case invalid, tooLarge, storage
    var errorDescription: String? {
        switch self {
        case .invalid: L10n.string("backup.invalid")
        case .tooLarge: L10n.string("backup.large")
        case .storage: L10n.string("mastery.save.error")
        }
    }
}

struct BackupDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    var data: Data
    init(data: Data) { self.data = data }
    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else { throw BackupError.invalid }
        self.data = data
    }
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}

struct BackupView: View {
    @ObservedObject private var reminder = BackupReminder.shared
    @ObservedObject var settings: AppSettingsStore
    @Environment(\.dismiss) private var dismiss
    @State private var exporting = false
    @State private var importing = false
    @State private var busy = false
    @State private var document: BackupDocument?
    @State private var pending: FretMapBackup?
    @State private var confirmRestore = false
    @State private var message: String?
    @State private var isError = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("backup.description")
                    Button { exportBackup() } label: { Label("backup.export", systemImage: "square.and.arrow.up") }
                    Button { importing = true } label: { Label("backup.import", systemImage: "square.and.arrow.down") }
                }
                Section("backup.reminder.title") {
                    Text(L10n.string(reminder.status))
                    if let expiration = reminder.expiration {
                        Text(expiration, format: .dateTime.day().month().year().hour().minute())
                    }
                    Button("backup.reminder.settings") {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                }
                Section { Text("backup.hint").font(.footnote).foregroundStyle(.secondary) }
                if busy { ProgressView("backup.working") }
            }
            .disabled(busy)
            .navigationTitle("backup.title").navigationBarTitleDisplayMode(.inline)
            .toolbar { Button("mastery.done") { dismiss() }.disabled(busy) }
            .interactiveDismissDisabled(busy)
            .fileExporter(isPresented: $exporting, document: document, contentType: .json,
                          defaultFilename: "FretMap-Backup-\(Date().formatted(.iso8601.year().month().day().dateSeparator(.dash)))") { result in
                switch result {
                case .success: show(L10n.string("backup.export.success"))
                case .failure(let error): show(error.localizedDescription, error: true)
                }
                document = nil
            }
            .fileImporter(isPresented: $importing, allowedContentTypes: [.json]) { result in
                switch result {
                case .success(let url): readBackup(url)
                case .failure(let error): show(error.localizedDescription, error: true)
                }
            }
            .confirmationDialog("backup.confirm", isPresented: $confirmRestore, titleVisibility: .visible) {
                Button("backup.replace", role: .destructive) { restoreBackup() }
                Button("mastery.cancel", role: .cancel) { pending = nil }
            } message: {
                if let pending {
                    Text("\(pending.createdAt.formatted(date: .abbreviated, time: .shortened)) · \(pending.exercises.count) \(L10n.string("backup.exercises"))")
                }
            }
            .alert(isError ? "mastery.error" : "backup.title", isPresented: Binding(get: { message != nil }, set: { if !$0 { message = nil } })) {
                Button("OK") { message = nil }
            } message: { Text(message ?? "") }
        }
    }

    private func show(_ text: String, error: Bool = false) { isError = error; message = text }

    private func exportBackup() {
        busy = true
        Task { @MainActor in
            defer { busy = false }
            do {
                let store = MasteryStore()
                let backup = try store.makeBackup(settings: settings.backupData())
                let data = try await Task.detached(priority: .userInitiated) {
                    let data = try JSONEncoder().encode(backup)
                    guard data.count <= 100 * 1024 * 1024 else { throw BackupError.tooLarge }
                    return data
                }.value
                document = BackupDocument(data: data)
                exporting = true
            } catch { show(error.localizedDescription, error: true) }
        }
    }

    private func readBackup(_ url: URL) {
        busy = true
        Task { @MainActor in
            defer { busy = false }
            do {
                let backup = try await Task.detached(priority: .userInitiated) {
                    let access = url.startAccessingSecurityScopedResource()
                    defer { if access { url.stopAccessingSecurityScopedResource() } }
                    var readError: Error?
                    var decoded: FretMapBackup?
                    var coordinationError: NSError?
                    NSFileCoordinator().coordinate(readingItemAt: url, options: [], error: &coordinationError) { location in
                        do {
                            let size = try location.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
                            guard size <= 100 * 1024 * 1024 else { throw BackupError.tooLarge }
                            let data = try Data(contentsOf: location)
                            guard data.count <= 100 * 1024 * 1024 else { throw BackupError.tooLarge }
                            let value = try JSONDecoder().decode(FretMapBackup.self, from: data)
                            try value.validate()
                            decoded = value
                        } catch { readError = error }
                    }
                    if let error = coordinationError ?? readError as NSError? { throw error }
                    guard let decoded else { throw BackupError.invalid }
                    return decoded
                }.value
                _ = try AppSettingsStore.preparedBackup(backup.settings)
                pending = backup
                confirmRestore = true
            } catch { show(error.localizedDescription, error: true) }
        }
    }

    private func restoreBackup() {
        guard let pending else { return }
        busy = true
        Task { @MainActor in
            defer { busy = false; self.pending = nil }
            do {
                let prepared = try AppSettingsStore.preparedBackup(pending.settings)
                let store = MasteryStore()
                try store.restoreBackup(pending)
                settings.applyBackup(prepared)
                show(L10n.string("backup.import.success"))
            } catch { show(error.localizedDescription, error: true) }
        }
    }
}
