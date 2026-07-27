import SwiftUI

struct HarmonyRootView: View {
    @ObservedObject var store: AppSettingsStore
    let noteNames: [String]
    let isPortrait: Bool

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
        Picker("Гармония", selection: modeSelection) {
            ForEach(HarmonyMode.allCases) { mode in
                if isPortrait {
                    Image(systemName: iconName(for: mode))
                        .accessibilityLabel(mode.title)
                        .tag(mode)
                } else {
                    Text(mode.title)
                        .tag(mode)
                }
            }
        }
        .pickerStyle(.segmented)
        .font(isPortrait ? .caption : .body)
        .padding(isPortrait ? 8 : 12)
        .padding(.leading, 52)
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
            SavedHarmonyView(noteNames: noteNames, store: store)
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
