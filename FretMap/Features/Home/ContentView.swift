import SwiftUI

struct ContentView: View {
    @StateObject private var store: AppSettingsStore

    init(store: AppSettingsStore = AppSettingsStore()) {
        _store = StateObject(wrappedValue: store)
    }

    var body: some View {
        HomeCoordinatorView(store: store)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
