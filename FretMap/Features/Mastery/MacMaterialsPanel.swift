#if targetEnvironment(macCatalyst)
import SwiftUI
import UniformTypeIdentifiers
import UIKit

struct MacMaterialsPanel: View {
    enum Target { case song(UUID), exercise(UUID) }
    @ObservedObject var store: MasteryStore
    let target: Target
    @Binding var isImporting: Bool
    @Binding var addingLink: Bool
    var showsHeading = true
    @State private var pickingFiles = false
    @State private var dropTargeted = false
    @State private var selectedPDF: MasteryPDF?
    @State private var selectedPhoto: PhotoSelection?
    private struct PhotoSelection: Identifiable { let id: String }
    private var song: MasterySong? {
        if case .song(let id) = target { return store.song(id) }
        return nil
    }
    private var exercise: MasteryExercise? {
        if case .exercise(let id) = target { return store.exercise(id) }
        return nil
    }
    private var inherited: MasterySong? {
        if case .exercise(let id) = target { return store.inheritedMaterials(for: id) }
        return nil
    }
    private var photos: [String] { song?.attachedPhotos ?? exercise?.photos ?? [] }
    private var pdfs: [MasteryPDF] { song?.attachedPDFs ?? exercise?.attachedPDFs ?? [] }
    private var links: [String] { song?.materialLinks ?? exercise?.videoLinks ?? [] }
    private var titles: [String: String] { song?.materialLinkTitles ?? exercise?.linkTitles ?? [:] }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            if showsHeading { Text("song.materials").font(.headline) }
            attachments(photos: photos, pdfs: pdfs, links: links, titles: titles, inherited: false)
            HStack {
                Button { pickingFiles = true } label: {
                    Label("mac.materials.add", systemImage: "doc.badge.plus")
                }.disabled(isImporting || (photos.count >= 3 && !pdfs.isEmpty))
                Spacer()
                if isImporting { ProgressView().controlSize(.small) }
            }
            Label(dropTargeted ? "mac.materials.drop.active" : "mac.materials.drop.hint", systemImage: "square.and.arrow.down")
                .font(.callout).foregroundStyle(dropTargeted ? AppColors.rootText : .secondary)
                .frame(maxWidth: .infinity, minHeight: 54)
                .background(AppColors.rootText.opacity(dropTargeted ? 0.15 : 0.04), in: RoundedRectangle(cornerRadius: 8))
                .overlay(NativeMaterialDropTarget(targeted: $dropTargeted, enabled: !isImporting, receive: importProviders))
            Text("mac.materials.limits").font(.caption).foregroundStyle(.secondary)
            if let inherited, !inherited.attachedPhotos.isEmpty || !inherited.attachedPDFs.isEmpty || !(inherited.materialLinks ?? []).isEmpty {
                Divider()
                Label("mac.materials.inherited", systemImage: "music.note.list").font(.subheadline.bold())
                Text("mac.materials.inherited.hint").font(.caption).foregroundStyle(.secondary)
                attachments(photos: inherited.attachedPhotos, pdfs: inherited.attachedPDFs,
                            links: (inherited.materialLinks ?? []).filter { !links.contains($0) },
                            titles: inherited.materialLinkTitles ?? [:], inherited: true)
            }
            Button("mastery.links.add") { addingLink = true }
                .disabled(isImporting)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .buttonStyle(.borderless)
        .contentShape(Rectangle())
        .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(AppColors.rootText.opacity(dropTargeted ? 1 : 0), style: StrokeStyle(lineWidth: 2, dash: [7, 4])).allowsHitTesting(false))
        .fileImporter(isPresented: $pickingFiles, allowedContentTypes: [.image, .pdf], allowsMultipleSelection: true) { result in
            switch result {
            case .success(let urls): importFiles(urls)
            case .failure(let error):
                if !FileSelectionError.isCancellation(error) { store.error = error.localizedDescription }
            }
        }
        .fullScreenCover(item: $selectedPDF) { MasteryPDFViewer(url: store.photoURL($0.id), name: $0.name) }
        .fullScreenCover(item: $selectedPhoto) { MasteryPhotoViewer(url: store.photoURL($0.id)) }
    }

    @ViewBuilder
    private func attachments(photos: [String], pdfs: [MasteryPDF], links: [String], titles: [String: String], inherited: Bool) -> some View {
        if !photos.isEmpty {
            ScrollView(.horizontal) {
                HStack(spacing: 8) {
                    ForEach(photos, id: \.self) { name in
                        Button { selectedPhoto = PhotoSelection(id: name) } label: {
                            MasteryThumbnail(url: store.photoURL(name)).frame(width: 120, height: 90)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }.buttonStyle(.plain).accessibilityLabel("mastery.photos")
                        .contextMenu { if !inherited { Button("mastery.delete", role: .destructive) { removePhoto(name) } } }
                    }
                }
            }
        }
        ForEach(pdfs) { pdf in
            Button { selectedPDF = pdf } label: {
                Label(pdf.name, systemImage: "doc.richtext").lineLimit(2).multilineTextAlignment(.leading)
            }.contextMenu { if !inherited { Button("mastery.delete", role: .destructive) { removePDF(pdf.id) } } }
        }
        ForEach(links, id: \.self) { link in
            HStack {
                if let url = URL(string: link) {
                    Link(destination: url) { Label(titles[link] ?? link, systemImage: "arrow.up.right.square").lineLimit(2) }
                }
                Spacer()
                if !inherited {
                    Button(role: .destructive) { removeLink(link) } label: { Image(systemName: "trash").foregroundStyle(.red) }
                        .accessibilityLabel("mastery.delete")
                }
            }
        }
    }

    private func importFiles(_ urls: [URL]) {
        importMaterials(count: urls.count) { index in
            try await Task.detached(priority: .userInitiated) { try MasteryMaterialReader.read(urls[index]) }.value
        }
    }

    private func importProviders(_ providers: [NSItemProvider]) {
        importMaterials(count: providers.count) { index in
            try await MasteryMaterialReader.droppedFile(from: providers[index])
        }
    }

    private func importMaterials(count: Int, load: @escaping @MainActor (Int) async throws -> MasteryMaterialReader.File) {
        guard !isImporting, count > 0 else { return }
        isImporting = true
        Task { @MainActor in
            defer { isImporting = false }
            var errors: [String] = []
            for index in 0..<count {
                do {
                    let file = try await load(index)
                    if file.isPDF {
                        guard pdfs.isEmpty else { errors.append(L10n.string("mac.materials.limits")); continue }
                        switch target {
                        case .song(let id): try store.addSongPDF(data: file.data, name: file.name, to: id)
                        case .exercise(let id): try store.addPDF(data: file.data, name: file.name, to: id)
                        }
                    } else {
                        guard photos.count < 3 else { errors.append(L10n.string("mac.materials.limits")); continue }
                        guard let image = UIImage(data: file.data) else { errors.append(L10n.string("mastery.photo.error")); continue }
                        switch target {
                        case .song(let id): try store.addSongPhoto(image, to: id)
                        case .exercise(let id): store.addPhoto(image, to: id)
                        }
                    }
                } catch { errors.append(error.localizedDescription) }
            }
            if !errors.isEmpty { store.error = Array(Set(errors)).sorted().joined(separator: "\n") }
        }
    }

    private func removePhoto(_ name: String) {
        switch target {
        case .song(let id): store.removeSongPhoto(name, from: id)
        case .exercise(let id): store.removePhoto(name, from: id)
        }
    }
    private func removePDF(_ name: String) {
        switch target {
        case .song(let id): store.removeSongPDF(name, from: id)
        case .exercise(let id): store.removePDF(name, from: id)
        }
    }
    private func removeLink(_ link: String) {
        switch target {
        case .song(let id): store.updateSong(id) { $0.materialLinks?.removeAll { $0 == link }; $0.materialLinkTitles?.removeValue(forKey: link) }
        case .exercise(let id): store.update(id) { $0.videoLinks?.removeAll { $0 == link }; $0.linkTitles?.removeValue(forKey: link) }
        }
    }
}

private struct NativeMaterialDropTarget: UIViewRepresentable {
    @Binding var targeted: Bool
    let enabled: Bool
    let receive: ([NSItemProvider]) -> Void
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.accessibilityIdentifier = "mac.materials.dropSurface"
        view.backgroundColor = .clear
        view.addInteraction(UIDropInteraction(delegate: context.coordinator))
        context.coordinator.region = view
        return view
    }
    func updateUIView(_ uiView: UIView, context: Context) { context.coordinator.owner = self }
    func makeCoordinator() -> Coordinator { Coordinator(self) }
    final class Coordinator: NSObject, UIDropInteractionDelegate {
        var owner: NativeMaterialDropTarget
        weak var region: UIView?
        init(_ owner: NativeMaterialDropTarget) { self.owner = owner }
        private func inside(_ session: UIDropSession) -> Bool {
            guard owner.enabled, let region, let window = region.window,
                  window.bounds.contains(session.location(in: window)),
                  region.bounds.contains(session.location(in: region)) else { return false }
            var ancestor: UIView? = region
            while let view = ancestor {
                if view.isHidden || view.alpha == 0 { return false }
                ancestor = view.superview
            }
            return true
        }
        func dropInteraction(_ interaction: UIDropInteraction, canHandle session: UIDropSession) -> Bool {
            owner.enabled && session.hasItemsConforming(toTypeIdentifiers: MasteryMaterialReader.dropTypes)
        }
        func dropInteraction(_ interaction: UIDropInteraction, sessionDidUpdate session: UIDropSession) -> UIDropProposal {
            let accepts = inside(session)
            owner.targeted = accepts
            return UIDropProposal(operation: accepts ? .copy : .cancel)
        }
        func dropInteraction(_ interaction: UIDropInteraction, sessionDidExit session: UIDropSession) { owner.targeted = false }
        func dropInteraction(_ interaction: UIDropInteraction, sessionDidEnd session: UIDropSession) { owner.targeted = false }
        func dropInteraction(_ interaction: UIDropInteraction, performDrop session: UIDropSession) {
            owner.targeted = false
            guard inside(session) else { return }
            owner.receive(session.items.map(\.itemProvider).filter { provider in
                MasteryMaterialReader.dropTypes.contains { provider.hasItemConformingToTypeIdentifier($0) }
            })
        }
    }
}

nonisolated enum MasteryMaterialReader {
    static let dropTypes = [UTType.fileURL.identifier, UTType.url.identifier, UTType.pdf.identifier, UTType.image.identifier]
    struct File: Sendable { let data: Data; let isPDF: Bool; var name: String = "" }
    @MainActor static func droppedURL(from provider: NSItemProvider) async -> URL? {
        await withCheckedContinuation { continuation in
            let type = provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) ? UTType.fileURL : .url
            provider.loadItem(forTypeIdentifier: type.identifier, options: nil) { item, _ in
                let url = (item as? URL)
                    ?? (item as? Data).flatMap { URL(dataRepresentation: $0, relativeTo: nil) }
                    ?? (item as? String).flatMap { URL(string: $0) }
                continuation.resume(returning: url?.isFileURL == true ? url : nil)
            }
        }
    }

    @MainActor static func droppedFile(from provider: NSItemProvider) async throws -> File {
        let type: UTType? = provider.hasItemConformingToTypeIdentifier(UTType.pdf.identifier) ? .pdf :
            provider.registeredTypeIdentifiers.compactMap { UTType($0) }.first { $0.conforms(to: .image) }
        if let type {
            let name = provider.suggestedName
            do {
                return try await withCheckedThrowingContinuation { continuation in
                    provider.loadFileRepresentation(forTypeIdentifier: type.identifier) { url, error in
                        do {
                            guard let url else { throw error ?? MaterialError.unsupported }
                            // NSItemProvider deletes this temporary file when the callback returns.
                            // Read its contents here, not after resuming the continuation.
                            let file = try read(url, contentType: type, name: name)
                            continuation.resume(returning: file)
                        } catch { continuation.resume(throwing: error) }
                    }
                }
            } catch {
                if error is PDFImportError { throw error }
                // Some providers expose data, but no file representation (e.g. an image preview).
                let data: Data? = await withCheckedContinuation { continuation in
                    _ = provider.loadDataRepresentation(for: type) { data, _ in continuation.resume(returning: data) }
                }
                if let data {
                    if type.conforms(to: .pdf), data.count > 5 * 1024 * 1024 { throw PDFImportError.invalid }
                    return File(data: data, isPDF: type.conforms(to: .pdf), name: filename(name, type: type))
                }
            }
        }
        guard let url = await droppedURL(from: provider) else { throw MaterialError.unsupported }
        return try await Task.detached(priority: .userInitiated) { try read(url) }.value
    }

    private static func filename(_ name: String?, type: UTType) -> String {
        let name = name.flatMap { $0.isEmpty ? nil : URL(fileURLWithPath: $0).lastPathComponent } ?? "Material"
        return URL(fileURLWithPath: name).pathExtension.isEmpty ? name + "." + (type.preferredFilenameExtension ?? "bin") : name
    }

    static func read(_ url: URL, contentType: UTType? = nil, name: String? = nil) throws -> File {
        let access = url.startAccessingSecurityScopedResource()
        defer { if access { url.stopAccessingSecurityScopedResource() } }
        let type = contentType ?? (try? url.resourceValues(forKeys: [.contentTypeKey]).contentType) ?? UTType(filenameExtension: url.pathExtension)
        if type?.conforms(to: .pdf) == true { return File(data: try MasteryPDFReader.read(url), isPDF: true, name: filename(name ?? url.lastPathComponent, type: .pdf)) }
        guard let type, type.conforms(to: .image) else { throw MaterialError.unsupported }
        return File(data: try Data(contentsOf: url), isPDF: false, name: filename(name ?? url.lastPathComponent, type: type))
    }
    enum MaterialError: LocalizedError {
        case unsupported
        var errorDescription: String? { L10n.string("mac.materials.invalid") }
    }
}
#endif
