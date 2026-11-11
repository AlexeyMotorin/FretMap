import SwiftUI

nonisolated enum MaterialLinkAddress {
    static func url(from input: String) -> URL? {
        let text = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !text.contains(where: \.isWhitespace) else { return nil }
        let candidate = text.contains(":") ? text : "https://" + text
        guard let url = URL(string: candidate),
              ["http", "https"].contains(url.scheme?.lowercased() ?? ""),
              let host = url.host, host.contains("."),
              url.user == nil, url.password == nil else { return nil }
        return url
    }
}

#if targetEnvironment(macCatalyst)
struct MacMaterialLinkEditor: View {
    let existingLinks: [String]
    var onClose: (() -> Void)? = nil
    let onSave: (String, String) -> Bool
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var address = ""
    @FocusState private var addressFocused: Bool

    private var url: URL? { MaterialLinkAddress.url(from: address) }
    private var isDuplicate: Bool { url.map { existingLinks.contains($0.absoluteString) } ?? false }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("mastery.links.add").font(.title2.bold())
                Spacer()
                Button(action: close) { Image(systemName: "xmark").frame(width: 32, height: 32) }
                    .accessibilityLabel("mastery.cancel").keyboardShortcut(.cancelAction)
            }
            TextField("mastery.links.url", text: $address)
                .textFieldStyle(.roundedBorder).focused($addressFocused)
                .textInputAutocapitalization(.never).autocorrectionDisabled()
            TextField("mastery.links.name", text: $title).textFieldStyle(.roundedBorder)
            Text(isDuplicate ? "mastery.links.duplicate" : "mac.links.hint")
                .font(.caption).foregroundStyle(.secondary)
            HStack {
                Spacer()
                Button("mastery.cancel", action: close)
                Button {
                    guard let url, !isDuplicate else { return }
                    let name = title.trimmingCharacters(in: .whitespacesAndNewlines)
                    if onSave(url.absoluteString, name.isEmpty ? (url.host ?? url.absoluteString) : name) { close() }
                } label: { Label("mastery.save", systemImage: "checkmark") }
                    .buttonStyle(.borderedProminent).keyboardShortcut(.defaultAction)
                    .disabled(url == nil || isDuplicate)
            }
        }
        .padding(28).frame(maxWidth: 560)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(AppBackgroundView().ignoresSafeArea())
        .preferredColorScheme(.dark)
        .onAppear { addressFocused = true }
    }

    private func close() {
        if let onClose { onClose() } else { dismiss() }
    }
}
#endif
