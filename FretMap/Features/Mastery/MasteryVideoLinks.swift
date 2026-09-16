import SwiftUI

struct MasteryVideoLinks: View {
    @ObservedObject var store: MasteryStore
    let exerciseID: UUID
    @State private var draft = ""
    @State private var title = ""
    @State private var adding = false
    @Environment(\.openURL) private var openURL
    private var exercise: MasteryExercise? { store.exercises.first { $0.id == exerciseID } }
    private var links: [String] { exercise?.videoLinks ?? [] }
    private var validURL: URL? {
        let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: text),
              ["http", "https"].contains(url.scheme?.lowercased() ?? ""),
              let host = url.host, !host.isEmpty else { return nil }
        return url
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("mastery.links").font(.headline)
            ForEach(links, id: \.self) { link in
                HStack {
                    Button {
                        if let url = URL(string: link) { openURL(url) }
                    } label: {
                        Label(exercise?.linkTitles?[link] ?? link, systemImage: "arrow.up.right.square")
                            .lineLimit(2).multilineTextAlignment(.leading)
                    }
                    Spacer()
                    Button(role: .destructive) {
                        store.update(exerciseID) {
                            $0.videoLinks?.removeAll { $0 == link }
                            $0.linkTitles?.removeValue(forKey: link)
                        }
                    } label: {
                        Image(systemName: "trash").frame(width: 44, height: 44)
                    }.accessibilityLabel("mastery.delete")
                }
            }
            Button("mastery.links.add") {
                draft = ""
                title = ""
                adding = true
            }
            Text("mastery.links.hint").font(.caption).foregroundStyle(.secondary)
        }
        .sheet(isPresented: $adding) {
            NavigationStack {
                Form {
                    TextField("mastery.links.name", text: $title)
                    TextField("mastery.links.url", text: $draft)
                        .keyboardType(.URL).textInputAutocapitalization(.never).autocorrectionDisabled()
                    if let url = validURL, links.contains(url.absoluteString) {
                        Text("mastery.links.duplicate").font(.caption).foregroundStyle(.secondary)
                    }
                }
                .navigationTitle("mastery.links.add")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("mastery.cancel") { adding = false }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("mastery.save") { save() }
                            .disabled(validURL == nil || title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                                      links.contains(validURL?.absoluteString ?? ""))
                    }
                }
            }
        }
    }
    private func save() {
        guard let url = validURL else { return }
        let name = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let link = url.absoluteString
        guard !name.isEmpty, !links.contains(link) else { return }
        store.update(exerciseID) {
            var current = $0.videoLinks ?? []
            guard !current.contains(link) else { return }
            current.append(link)
            $0.videoLinks = current
            var titles = $0.linkTitles ?? [:]
            titles[link] = name
            $0.linkTitles = titles
        }
        if links.contains(link) { adding = false }
    }
}
