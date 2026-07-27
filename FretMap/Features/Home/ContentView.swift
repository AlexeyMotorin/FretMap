import SwiftUI

struct ContentView: View {
    @StateObject private var store: AppSettingsStore
    @State private var customTuningTargetMode: AppMode?
    @State private var isCreatingSavedProgression = false

    init(store: AppSettingsStore = AppSettingsStore()) {
        _store = StateObject(wrappedValue: store)
    }

    var body: some View {
        HomeCoordinatorView(
            store: store,
            customTuningTargetMode: $customTuningTargetMode,
            isCreatingSavedProgression: $isCreatingSavedProgression
        )
        .fullScreenCover(isPresented: $isCreatingSavedProgression) {
            SavedHarmonyEditor(
                noteNames: store.accidentalStyle.noteNames,
                store: store
            )
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
