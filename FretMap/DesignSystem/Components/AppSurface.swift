import SwiftUI

private struct AppSurfaceModifier: ViewModifier {
    let fill: Color
    let cornerRadius: CGFloat
    let castsShadow: Bool

    func body(content: Content) -> some View {
        content
            .background(
                fill,
                in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(AppColors.border, lineWidth: 1)
            }
            .shadow(
                color: castsShadow ? AppColors.shadow : .clear,
                radius: castsShadow ? 12 : 0,
                y: castsShadow ? 6 : 0
            )
    }
}

extension View {
    func appSurface(
        fill: Color = AppColors.panel,
        cornerRadius: CGFloat = 8,
        castsShadow: Bool = false
    ) -> some View {
        modifier(
            AppSurfaceModifier(
                fill: fill,
                cornerRadius: cornerRadius,
                castsShadow: castsShadow
            )
        )
    }
}
