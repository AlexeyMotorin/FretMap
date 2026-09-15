import SwiftUI
import PDFKit

nonisolated enum PDFImportError: LocalizedError {
    case invalid
    var errorDescription: String? { NSLocalizedString("mastery.pdf.error", comment: "PDF import error") }
}

nonisolated enum MasteryPDFReader {
    static func read(_ url: URL) throws -> Data {
        let access = url.startAccessingSecurityScopedResource()
        defer { if access { url.stopAccessingSecurityScopedResource() } }
        var output: Data?
        var failure: Error?
        var coordinationError: NSError?
        NSFileCoordinator().coordinate(readingItemAt: url, options: [], error: &coordinationError) { location in
            do {
                let size = try location.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
                guard size <= 5 * 1024 * 1024 else { throw PDFImportError.invalid }
                let data = try Data(contentsOf: location)
                guard data.count <= 5 * 1024 * 1024 else { throw PDFImportError.invalid }
                output = data
            } catch { failure = error }
        }
        if let coordinationError { throw coordinationError }
        if let failure { throw failure }
        guard let output else { throw PDFImportError.invalid }
        return output
    }
}

struct MasteryPDFViewer: View {
    let url: URL
    let name: String
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            PDFContent(url: url)
                .navigationTitle(name).navigationBarTitleDisplayMode(.inline)
                .toolbar { Button("mastery.done") { dismiss() } }
        }
    }
}

private struct PDFContent: UIViewRepresentable {
    let url: URL
    func makeUIView(context: Context) -> PDFView {
        let view = PDFView()
        view.document = PDFDocument(url: url)
        view.autoScales = true
        view.displayMode = .singlePageContinuous
        view.displayDirection = .vertical
        view.backgroundColor = .secondarySystemBackground
        return view
    }
    func updateUIView(_ uiView: PDFView, context: Context) { }
}
