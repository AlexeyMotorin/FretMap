import SwiftUI

struct HarmonyRootView: View {
    @ObservedObject var store: AppSettingsStore
    let noteNames: [String]
    let isPortrait: Bool
    let onBack: () -> Void
    let onCreateSavedProgression: () -> Void

    var body: some View {
        GeometryReader { proxy in
            VStack(spacing: 0) {
                modePicker

                selectedHarmonyView
                    .frame(width: proxy.size.width, alignment: .topLeading)
                    .frame(maxHeight: .infinity, alignment: .topLeading)
                    .clipped()
            }
        }
        .ignoresSafeArea(.container, edges: .bottom)
    }

    private var modePicker: some View {
        HStack(spacing: 8) {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .frame(width: 44, height: 48)
                    .foregroundStyle(AppColors.primaryText)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Назад к выбору режима")

            ForEach(HarmonyMode.allCases) { mode in
                let selected = store.harmonyMode == mode
                Button { modeSelection.wrappedValue = mode } label: {
                    VStack(spacing: 4) {
                        Image(systemName: iconName(for: mode))
                            .font(.system(size: 17, weight: .semibold))
                        Text(mode.title)
                            .font(.system(size: isPortrait ? 9 : 11, weight: .semibold))
                            .lineLimit(1).minimumScaleFactor(0.7)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .foregroundStyle(selected ? AppColors.rootText : AppColors.mutedText)
                    .background(selected ? AppColors.rootText.opacity(0.12) : Color.clear,
                                in: RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(mode.title)
                .accessibilityAddTraits(selected ? .isSelected : [])
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(AppColors.panel.opacity(0.72))
    }

    @ViewBuilder
    private var selectedHarmonyView: some View {
        switch store.harmonyMode {
        case .functional:
            FunctionalHarmonyView(noteNames: noteNames, store: store)
        case .modal:
            ModalHarmonyView(noteNames: noteNames, store: store)
        case .popular:
            PopularHarmonyView(noteNames: noteNames, store: store)
        case .saved:
            SavedHarmonyView(
                noteNames: noteNames,
                store: store,
                onCreateProgression: onCreateSavedProgression
            )
        }
    }

    private var modeSelection: Binding<HarmonyMode> {
        Binding(
            get: { store.harmonyMode },
            set: { mode in
                withoutAnimation {
                    store.harmonyMode = mode
                    if mode == .popular {
                        store.popularCollectionMode = .popular
                    }
                }
            }
        )
    }

    private func iconName(for mode: HarmonyMode) -> String {
        switch mode {
        case .functional: "arrow.triangle.branch"
        case .modal: "circle.grid.2x2.fill"
        case .popular: "flame.fill"
        case .saved: "folder.fill"
        }
    }

    private func withoutAnimation(_ updates: () -> Void) {
        var transaction = Transaction()
        transaction.animation = nil
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            updates()
        }
    }
}
