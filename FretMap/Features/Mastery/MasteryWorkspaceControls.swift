import SwiftUI

enum MasteryWorkspaceLayout {
    static func usesList(_ preference: Bool) -> Bool {
        #if targetEnvironment(macCatalyst)
        return preference
        #else
        return false
        #endif
    }

    static func columns(list: Bool) -> [GridItem] {
        usesList(list) ? [GridItem(.flexible())] : columns
    }
    static var columns: [GridItem] {
        #if targetEnvironment(macCatalyst)
        return [GridItem(.adaptive(minimum: 230, maximum: 340), alignment: .top)]
        #else
        return [GridItem(.flexible(), alignment: .top), GridItem(.flexible(), alignment: .top)]
        #endif
    }
}

struct MasteryWorkspaceControls: View {
    let openArchive: () -> Void
    let openStatistics: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Text("mastery.active").font(.headline).foregroundStyle(.secondary)
            Spacer()
            #if targetEnvironment(macCatalyst)
            MasteryLayoutPicker()
            #endif
            control("archivebox", label: "mastery.archive", action: openArchive)
            control("calendar", label: "mastery.daily.title", action: openStatistics)
        }
    }

    private func control(_ icon: String, label: LocalizedStringKey, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon).font(.title3).frame(width: 44, height: 44)
                .background(AppColors.control, in: RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain).foregroundStyle(AppColors.rootText).accessibilityLabel(label)
    }
}

struct MasteryLayoutPicker: View {
    @AppStorage("mac.mastery.listLayout") private var list = false
    var body: some View {
        Picker("mastery.view", selection: $list) {
            Label("mastery.view.tiles", systemImage: "square.grid.2x2").tag(false)
            Label("mastery.view.list", systemImage: "list.bullet").tag(true)
        }
        .pickerStyle(.segmented)
        .frame(width: 200)
    }
}

struct MasteryLibraryRow: View {
    let title: String
    let subtitle: String
    let detail: String
    let progress: Double
    var icon = "music.note.list"
    var photoURL: URL? = nil
    var completed = false

    var body: some View {
        HStack(spacing: 16) {
            Group {
                if let photoURL {
                    MasteryThumbnail(url: photoURL)
                } else {
                    Image(systemName: completed ? "checkmark.circle.fill" : icon)
                        .font(.title2).foregroundStyle(completed ? .green : AppColors.rootText)
                }
            }
            .frame(width: 64, height: 56)
            .background(AppColors.control, in: RoundedRectangle(cornerRadius: 8))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            VStack(alignment: .leading, spacing: 6) {
                Text(title).font(.headline).lineLimit(2)
                Text(subtitle).font(.subheadline).foregroundStyle(.secondary).lineLimit(1)
            }
            Spacer(minLength: 12)
            VStack(alignment: .trailing, spacing: 8) {
                Text(detail).font(.subheadline).foregroundStyle(.secondary)
                ProgressView(value: progress).frame(width: 120)
            }
            Image(systemName: "chevron.right").font(.caption).foregroundStyle(.secondary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.panel, in: RoundedRectangle(cornerRadius: 12))
        .contentShape(Rectangle())
    }
}
