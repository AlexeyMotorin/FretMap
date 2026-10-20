import SwiftUI
import UniformTypeIdentifiers

/// The Songs workspace owns collections; individual exercises continue to use the
/// existing practice flow and are only distinguished by their `songID`.
struct SongLibraryView: View {
    @AppStorage("mac.mastery.listLayout") private var listLayout = false
    @ObservedObject var store: MasteryStore
    @Binding var adding: Bool
    @Binding var dailyStatistics: Bool
    @State private var showingArchive = false
    @State private var deleting: MasterySong?
    @State private var openedSongID: UUID?
    @State private var search = ""
    @State private var newestFirst = true

    private var songs: [MasterySong] {
        store.songs.filter {
            !$0.isArchived && (search.isEmpty || $0.title.localizedCaseInsensitiveContains(search) || $0.artist.localizedCaseInsensitiveContains(search))
        }.sorted { newestFirst ? $0.createdAt > $1.createdAt : $0.createdAt < $1.createdAt }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            MasteryWorkspaceControls(openArchive: { showingArchive = true }, openStatistics: { dailyStatistics = true })
            TextField("song.search", text: $search).textFieldStyle(.roundedBorder)
            HStack {
                Text("song.library").font(.caption).foregroundStyle(.secondary)
                Spacer()
                Button { newestFirst.toggle() } label: {
                    Label(newestFirst ? "mastery.newest" : "song.oldest", systemImage: "arrow.up.arrow.down")
                }.font(.caption)
            }

            if songs.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "music.note.list").font(.system(size: 42)).foregroundStyle(AppColors.rootText)
                    Text(search.isEmpty ? "song.empty" : "song.no.matches").font(.headline)
                    if search.isEmpty {
                        Text("song.empty.hint").font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 44)
            } else {
                LazyVGrid(columns: MasteryWorkspaceLayout.columns(list: listLayout), spacing: 14) {
                    ForEach(songs) { song in
                        NavigationLink { SongDetailView(store: store, songID: song.id) } label: {
                            if MasteryWorkspaceLayout.usesList(listLayout) {
                                let parts = store.parts(for: song.id)
                                let learned = parts.filter(\.isArchived).count
                                MasteryLibraryRow(title: song.title, subtitle: song.artist,
                                                  detail: "\(learned)/\(parts.count) · \(L10n.string("song.parts"))",
                                                  progress: parts.isEmpty ? 0 : Double(learned) / Double(parts.count),
                                                  completed: store.isLearned(song))
                            } else {
                                songCard(song)
                            }
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            if song.isArchived {
                                Button { store.setSongArchived(false, id: song.id) } label: {
                                    Label("song.reactivate", systemImage: "arrow.uturn.backward")
                                }
                            } else {
                                Button { store.setSongArchived(true, id: song.id) } label: {
                                    Label("song.archive", systemImage: "archivebox")
                                }
                                    .disabled(!store.isLearned(song))
                            }
                            Button(role: .destructive) { deleting = song } label: {
                                Label {
                                    Text("song.delete").foregroundStyle(.red)
                                } icon: {
                                    Image(systemName: "trash").foregroundStyle(.red)
                                }
                            }
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $adding) {
            SongEditor(store: store) { song in
                openedSongID = song.id
            }
        }
        .fullScreenCover(isPresented: $showingArchive) { SongArchiveView(store: store) }
        .navigationDestination(isPresented: Binding(get: { openedSongID != nil }, set: { if !$0 { openedSongID = nil } })) {
            if let openedSongID { SongDetailView(store: store, songID: openedSongID) }
        }
        .alert("song.delete.title", isPresented: Binding(get: { deleting != nil }, set: { if !$0 { deleting = nil } })) {
            Button("song.delete", role: .destructive) {
                if let deleting { store.deleteSong(deleting.id) }
                deleting = nil
            }
            Button("mastery.cancel", role: .cancel) { deleting = nil }
        } message: { Text("song.delete.message") }
    }

    private func songCard(_ song: MasterySong) -> some View {
        let parts = store.parts(for: song.id)
        let learned = store.isLearned(song)
        return VStack(alignment: .leading, spacing: 10) {
            Image(systemName: song.isArchived ? "checkmark.circle.fill" : "music.note.list")
                .font(.system(size: 34)).foregroundStyle(song.isArchived ? .green : AppColors.rootText)
                .frame(maxWidth: .infinity, minHeight: 100)
                .background(AppColors.control, in: RoundedRectangle(cornerRadius: 8))
            VStack(alignment: .leading, spacing: 4) {
                Text(song.artist).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                Text(song.title).font(.headline).lineLimit(2).frame(height: 44, alignment: .topLeading)
                Text("\(parts.filter(\.isArchived).count)/\(parts.count) · \(L10n.string("song.parts"))")
                    .font(.caption).foregroundStyle(.secondary)
            }
            ProgressView(value: parts.isEmpty ? 0 : Double(parts.filter(\.isArchived).count) / Double(parts.count))
            if learned { Label("mastery.completed", systemImage: "checkmark.seal.fill").font(.caption).foregroundStyle(.green) }
        }
        .padding(12)
        .background(AppColors.panel, in: RoundedRectangle(cornerRadius: 12))
    }
}

private struct SongEditor: View {
    @ObservedObject var store: MasteryStore
    let onCreated: (MasterySong) -> Void
    let song: MasterySong?
    @Environment(\.dismiss) private var dismiss
    @State private var artist = ""
    @State private var title = ""

    init(store: MasteryStore, song: MasterySong? = nil, onCreated: @escaping (MasterySong) -> Void) {
        self.store = store
        self.song = song
        self.onCreated = onCreated
        _artist = State(initialValue: song?.artist ?? "")
        _title = State(initialValue: song?.title ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("song.artist", text: $artist)
                    TextField("song.name", text: $title)
                } footer: { Text("song.create.hint") }
            }
            .navigationTitle(song == nil ? "song.add" : "mastery.edit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("mastery.cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button(song == nil ? "song.create" : "mastery.save") {
                        var value = song.flatMap { store.song($0.id) } ?? MasterySong(title: "", artist: "")
                        value.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
                        value.artist = artist.trimmingCharacters(in: .whitespacesAndNewlines)
                        if store.save(value) { onCreated(value); dismiss() }
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || artist.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

private struct SongArchiveView: View {
    @AppStorage("mac.mastery.listLayout") private var listLayout = false
    @ObservedObject var store: MasteryStore
    @Environment(\.dismiss) private var dismiss

    private var songs: [MasterySong] { store.songs.filter(\.isArchived).sorted { $0.createdAt > $1.createdAt } }

    var body: some View {
        NavigationStack {
            Group {
                if songs.isEmpty {
                    VStack(spacing: 12) {
                        Spacer()
                        Image(systemName: "archivebox").font(.system(size: 40)).foregroundStyle(AppColors.rootText)
                        Text("song.archive.empty").font(.headline)
                        Text("song.archive.hint").font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center)
                        Spacer()
                    }
                    .padding(24)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .multilineTextAlignment(.center)
                } else {
                    ScrollView {
                    LazyVGrid(columns: MasteryWorkspaceLayout.columns(list: listLayout), spacing: 14) {
                        ForEach(songs) { song in
                            NavigationLink { SongDetailView(store: store, songID: song.id) } label: {
                                let parts = store.parts(for: song.id)
                                if MasteryWorkspaceLayout.usesList(listLayout) {
                                    MasteryLibraryRow(title: song.title, subtitle: song.artist,
                                                      detail: "\(parts.count)/\(parts.count) · \(L10n.string("song.parts"))",
                                                      progress: 1, completed: true)
                                } else {
                                VStack(alignment: .leading, spacing: 8) {
                                    Image(systemName: "checkmark.circle.fill").font(.system(size: 34)).foregroundStyle(.green)
                                        .frame(maxWidth: .infinity, minHeight: 92).background(AppColors.control, in: RoundedRectangle(cornerRadius: 8))
                                    Text(song.artist).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                                    Text(song.title).font(.headline).lineLimit(2).frame(height: 44, alignment: .topLeading)
                                    Text("\(parts.count)/\(parts.count) · \(L10n.string("song.parts"))").font(.caption).foregroundStyle(.secondary)
                                }
                                .padding(12).background(AppColors.panel, in: RoundedRectangle(cornerRadius: 12))
                                }
                            }
                            .buttonStyle(.plain)
                            .contextMenu {
                                Button { store.setSongArchived(false, id: song.id) } label: { Label("song.reactivate", systemImage: "arrow.uturn.backward") }
                            }
                        }
                    }.padding(16)
                    }
                }
            }
            .background(AppBackgroundView().ignoresSafeArea())
            .navigationTitle("mastery.archive")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                #if targetEnvironment(macCatalyst)
                ToolbarItem(placement: .primaryAction) { MasteryLayoutPicker() }
                #endif
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: { Image(systemName: "xmark") }
                        .accessibilityLabel("mastery.done")
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
        }
    }
}

private struct SongDetailView: View {
    @ObservedObject var store: MasteryStore
    let songID: UUID
    @Environment(\.dismiss) private var dismiss
    @State private var addingPart = false
    @State private var editingSong = false
    @State private var editingPart: MasteryExercise?
    @State private var deletingPart: MasteryExercise?
    @State private var addingMaterialLink = false
    @State private var selectedSongPDF: MasteryPDF?
    @State private var showingUnsavedChanges = false
    @State private var pickingPDF = false
    @State private var importingPDF = false
    @State private var importError: String?

    private var song: MasterySong? { store.song(songID) }
    private var parts: [MasteryExercise] { store.parts(for: songID) }

    var body: some View {
        Group {
            if let song {
                songContent(song)
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "music.note").font(.largeTitle)
                    Text("song.not.found").font(.headline)
                }
            }
        }
        .onAppear { store.beginEditingSong(songID) }
    }

    private func songContent(_ song: MasterySong) -> some View {
        List {
                    Section {
                        Text(song.artist).foregroundStyle(.secondary)
                        Text(song.title).font(.title3.weight(.semibold))
                        HStack {
                            Text("song.progress")
                            Spacer()
                            Text("\(parts.filter(\.isArchived).count)/\(parts.count)")
                                .foregroundStyle(.secondary)
                        }
                        if !song.isArchived {
                            Button { store.setSongArchived(true, id: song.id) } label: {
                                Label("song.archive", systemImage: "archivebox")
                            }
                            .disabled(!store.isLearned(song))
                        }
                    }
                    Section("song.materials") {
                        SongMaterials(store: store, songID: songID, addingLink: $addingMaterialLink, selectedPDF: $selectedSongPDF, pickingPDF: $pickingPDF)
                            .disabled(importingPDF)
                    }
                    Section("song.parts") {
                        if parts.isEmpty {
                            Text("song.parts.empty").foregroundStyle(.secondary)
                        }
                        ForEach(parts) { part in
                            NavigationLink { MasteryExerciseView(store: store, exerciseID: part.id) } label: {
                                HStack {
                                    Image(systemName: part.isArchived ? "checkmark.circle.fill" : "circle")
                                        .foregroundStyle(part.isArchived ? .green : .secondary)
                                    VStack(alignment: .leading) {
                                        Text(part.name)
                                        Text("\(part.targetBPM) BPM").font(.caption).foregroundStyle(.secondary)
                                    }
                                }
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) { deletingPart = part } label: {
                                    Label("mastery.delete", systemImage: "trash")
                                }
                                Button { editingPart = part } label: {
                                    Label("mastery.edit", systemImage: "pencil")
                                }
                                .tint(AppColors.rootText)
                            }
                        }
                        Button { addingPart = true } label: {
                            Label("song.part.add", systemImage: "plus.circle.fill")
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .frame(minHeight: 44)
                        }
                    }
        }
        .scrollContentBackground(.hidden)
        .background(AppBackgroundView().ignoresSafeArea())
        .navigationTitle(song.title)
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) { Button { attemptDismiss() } label: { Image(systemName: "chevron.left") } }
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button { if store.commitSong(songID) { store.beginEditingSong(songID) } } label: { Image(systemName: "checkmark") }
                    .disabled(importingPDF || !store.hasUnsavedSongChanges(songID)).accessibilityLabel("mastery.save")
                Button { editingSong = true } label: { Image(systemName: "pencil") }.accessibilityLabel("mastery.edit")
                Button { addingPart = true } label: { Image(systemName: "plus") }.accessibilityLabel("song.part.add")
            }
        }
        .sheet(isPresented: $addingPart) { MasteryEditor(store: store, exercise: nil, songID: songID) }
        .sheet(isPresented: $editingSong) { SongEditor(store: store, song: song) { _ in } }
        .sheet(isPresented: $addingMaterialLink) { SongMaterialLinkEditor(store: store, songID: songID) }
        .fullScreenCover(item: $selectedSongPDF) { pdf in MasteryPDFViewer(url: store.photoURL(pdf.id), name: pdf.name) }
        .fileImporter(isPresented: $pickingPDF, allowedContentTypes: [.pdf]) { result in
            switch result {
            case .success(let url):
                importingPDF = true
                Task { @MainActor in
                    defer { importingPDF = false }
                    do {
                        let data = try await Task.detached(priority: .userInitiated) { try MasteryPDFReader.read(url) }.value
                        try store.addSongPDF(data: data, name: url.lastPathComponent, to: songID)
                    } catch { importError = error.localizedDescription }
                }
            case .failure(let error): importError = error.localizedDescription
            }
        }
        .alert("mastery.error", isPresented: Binding(get: { importError != nil || store.error != nil }, set: { if !$0 { importError = nil; store.error = nil } })) {
            Button("OK") { importError = nil; store.error = nil }
        } message: { Text(importError ?? store.error ?? "") }
        .sheet(item: $editingPart) { MasteryEditor(store: store, exercise: $0) }
        .alert("mastery.delete.title", isPresented: Binding(get: { deletingPart != nil }, set: { if !$0 { deletingPart = nil } })) {
            Button("mastery.delete", role: .destructive) { if let deletingPart { store.delete(deletingPart.id) }; deletingPart = nil }
            Button("mastery.cancel", role: .cancel) { deletingPart = nil }
        } message: { Text("mastery.delete.message") }
        .alert("mastery.unsaved.title", isPresented: $showingUnsavedChanges) {
            Button("mastery.save") { if store.commitSong(songID) { dismiss() } }
            Button("mastery.discard", role: .destructive) { store.discardSongChanges(songID); dismiss() }
            Button("mastery.cancel", role: .cancel) { }
        } message: { Text("mastery.unsaved.message") }
    }

    private func attemptDismiss() {
        guard !importingPDF else { return }
        if store.hasUnsavedSongChanges(songID) { showingUnsavedChanges = true }
        else { store.discardSongChanges(songID); dismiss() }
    }
}

private struct SongMaterials: View {
    @ObservedObject var store: MasteryStore
    let songID: UUID
    @Binding var addingLink: Bool
    @Binding var selectedPDF: MasteryPDF?
    @Binding var pickingPDF: Bool

    private var song: MasterySong? { store.song(songID) }
    private var links: [String] { song?.materialLinks ?? [] }
    var body: some View {
        Group {
            if let song {
                ForEach(links, id: \.self) { link in
                    HStack {
                        if let url = URL(string: link) {
                            Link(destination: url) {
                                Label(song.materialLinkTitles?[link] ?? link, systemImage: "arrow.up.right.square")
                                    .lineLimit(2).multilineTextAlignment(.leading)
                            }
                        } else {
                            Text(song.materialLinkTitles?[link] ?? link).lineLimit(2)
                        }
                        Spacer()
                        Button(role: .destructive) {
                            store.updateSong(songID) {
                                $0.materialLinks?.removeAll { $0 == link }
                                $0.materialLinkTitles?.removeValue(forKey: link)
                            }
                        } label: { Image(systemName: "trash").foregroundStyle(.red) }
                    }
                }
                ForEach(song.attachedPDFs) { pdf in
                    Button { selectedPDF = pdf } label: {
                        Label(pdf.name, systemImage: "doc.richtext")
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .contextMenu {
                        Button("mastery.delete", role: .destructive) {
                            store.removeSongPDF(pdf.id, from: songID)
                        }
                    }
                }
                if song.attachedPDFs.isEmpty {
                    Button { pickingPDF = true } label: { Label("mastery.pdf.add", systemImage: "doc.badge.plus") }
                }
                Button { addingLink = true } label: {
                    Label("mastery.links.add", systemImage: "link.badge.plus")
                }
            }
        }
        .buttonStyle(.borderless)
    }

}

private struct SongMaterialLinkEditor: View {
    @ObservedObject var store: MasteryStore
    let songID: UUID
    @Environment(\.dismiss) private var dismiss
    @State private var linkTitle = ""
    @State private var linkURL = ""

    private var links: [String] { store.song(songID)?.materialLinks ?? [] }
    private var validURL: URL? {
        let text = linkURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: text), ["http", "https"].contains(url.scheme?.lowercased() ?? ""), url.host?.isEmpty == false else { return nil }
        return url
    }

    var body: some View {
        NavigationStack {
            Form {
                TextField("mastery.links.name", text: $linkTitle)
                TextField("mastery.links.url", text: $linkURL)
                    .keyboardType(.URL).textInputAutocapitalization(.never).autocorrectionDisabled()
            }
            .navigationTitle("mastery.links.add")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("mastery.cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("mastery.save") {
                        guard let url = validURL else { return }
                        let title = linkTitle.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !title.isEmpty, !links.contains(url.absoluteString) else { return }
                        store.updateSong(songID) {
                            $0.materialLinks = ($0.materialLinks ?? []) + [url.absoluteString]
                            var titles = $0.materialLinkTitles ?? [:]
                            titles[url.absoluteString] = title
                            $0.materialLinkTitles = titles
                        }
                        if links.contains(url.absoluteString) { dismiss() }
                    }
                    .disabled(validURL == nil || linkTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || links.contains(validURL?.absoluteString ?? ""))
                }
            }
        }
    }
}
