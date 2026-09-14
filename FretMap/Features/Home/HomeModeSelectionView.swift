import SwiftUI

struct HomeModeSelectionView: View {
    let isPortrait: Bool
    let containerSize: CGSize
    let onSelectMode: (AppMode) -> Void

    var body: some View {
        Group {
            if isPortrait {
                VStack(spacing: 22) {
                    Spacer(minLength: 12)
                    logo
                        .frame(maxWidth: 240, maxHeight: containerSize.height * 0.25)
                    modeButtons
                        .frame(maxWidth: 380)
                    Spacer(minLength: 24)
                        .frame(minHeight: containerSize.height * 0.12)
                }
                .offset(y: 18)
            } else {
                HStack(spacing: 44) {
                    logo
                        .frame(maxWidth: 330, maxHeight: 250)
                    modeButtons
                        .frame(width: 340)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .padding(.horizontal, 24)
        .frame(width: containerSize.width, height: containerSize.height)
    }

    private var modeButtons: some View {
        VStack(spacing: 12) {
            modeButton(.chords, systemName: "music.note", accent: AppColors.rootText)
            modeButton(.modes, systemName: "guitars", accent: AppColors.openStringStroke)
            modeButton(.harmony, systemName: "music.note.list", accent: AppColors.barre)
        }
    }

    private var logo: some View {
        Image("Logo")
            .resizable()
            .scaledToFit()
            .accessibilityHidden(true)
    }

    private func modeButton(_ mode: AppMode, systemName: String, accent: Color) -> some View {
        Button {
            onSelectMode(mode)
        } label: {
            HStack(spacing: 14) {
                Image(systemName: systemName)
                    .font(.system(size: 18, weight: .bold))
                    .symbolRenderingMode(.monochrome)
                    .foregroundStyle(accent)
                    .frame(width: 42, height: 42)
                    .background(accent.opacity(0.14), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

                Text(mode.title)
                    .font(.system(.title3, design: .rounded).weight(.bold))
                    .foregroundStyle(AppColors.primaryText)

                Spacer(minLength: 12)

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(AppColors.mutedText)
            }
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity, minHeight: 66)
            .background {
                LinearGradient(
                    colors: [accent.opacity(0.10), Color.clear],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            }
            .appSurface(fill: AppColors.elevatedPanel, castsShadow: true)
        }
        .buttonStyle(HomeModeButtonStyle())
    }
}

private struct HomeModeButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .opacity(configuration.isPressed ? 0.86 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

struct ModeBackButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "chevron.left")
                .font(.system(size: 16, weight: .black))
                .foregroundStyle(AppColors.primaryText)
                .frame(width: 40, height: 36)
                .appSurface(fill: AppColors.elevatedPanel, castsShadow: true)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Назад к выбору режима")
    }
}
