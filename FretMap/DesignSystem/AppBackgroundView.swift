import SwiftUI

struct AppBackgroundView: View {
    var body: some View {
        ZStack {
            AppColors.page

            LinearGradient(
                colors: [
                    AppColors.rootText.opacity(0.17),
                    Color.clear,
                    AppColors.barre.opacity(0.055)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            LinearGradient(
                colors: [
                    Color.clear,
                    AppColors.openStringStroke.opacity(0.035),
                    Color.black.opacity(0.32)
                ],
                startPoint: .topTrailing,
                endPoint: .bottomLeading
            )
        }
        .ignoresSafeArea()
    }
}
