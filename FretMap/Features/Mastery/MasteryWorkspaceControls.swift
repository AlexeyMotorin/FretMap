import SwiftUI

struct MasteryWorkspaceControls: View {
    let openArchive: () -> Void
    let openStatistics: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Text("mastery.active").font(.headline).foregroundStyle(.secondary)
            Spacer()
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
