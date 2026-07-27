import SwiftUI

struct AppBackgroundView: View {
    var body: some View {
        ZStack {
            Color(red: 0.025, green: 0.07, blue: 0.13)
            Image("Background")
                .resizable()
                .scaledToFill()
        }
        .ignoresSafeArea()
    }
}
