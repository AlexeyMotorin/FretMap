import SwiftUI

struct HomeModeSelectionView: View {
    let isPortrait: Bool
    let containerSize: CGSize
    let onSelectMode: (AppMode) -> Void

    var body: some View {
        Group {
            if isPortrait {
                VStack(spacing: 14) {
                    Spacer(minLength: 30)
                    modeButtons
                        .frame(maxWidth: 340)
                    logo
                        .frame(maxWidth: 300)
                        .padding(.top, 14)
                    Spacer(minLength: 30)
                }
            } else {
                HStack(spacing: 32) {
                    modeButtons
                        .frame(width: 300)
                    logo
                        .frame(maxWidth: 300, maxHeight: 230)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .padding(.horizontal, 24)
        .frame(width: containerSize.width, height: containerSize.height)
    }

    private var modeButtons: some View {
        VStack(spacing: 10) {
            modeButton(.chords, systemName: "music.note")
            modeButton(.modes, systemName: "guitars")
            modeButton(.harmony, systemName: "music.note.list")
        }
    }

    private var logo: some View {
        Image("Logo")
            .resizable()
            .scaledToFit()
            .accessibilityHidden(true)
    }

    private func modeButton(_ mode: AppMode, systemName: String) -> some View {
        Button {
            onSelectMode(mode)
        } label: {
            Label(mode.title, systemImage: systemName)
                .font(.system(.headline, design: .rounded).weight(.black))
                .foregroundStyle(AppColors.primaryText)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    AppColors.panel.opacity(0.94),
                    in: RoundedRectangle(cornerRadius: 8, style: .continuous)
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(AppColors.control, lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
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
                .background(
                    AppColors.control.opacity(0.96),
                    in: RoundedRectangle(cornerRadius: 8, style: .continuous)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Назад к выбору режима")
    }
}
