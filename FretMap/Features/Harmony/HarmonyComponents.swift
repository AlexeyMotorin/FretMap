import SwiftUI

struct TheoryHelpButton: View {
    let titleKey: String
    let bodyKey: String
    @State private var isPresented = false

    var body: some View {
        Button {
            isPresented = true
        } label: {
            Image(systemName: "questionmark.circle.fill")
                .font(.system(size: 19, weight: .semibold))
                .foregroundStyle(AppColors.mutedText)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(L10n.string("Справка"))
        .sheet(isPresented: $isPresented) {
            NavigationStack {
                ScrollView {
                    Text(L10n.string(bodyKey))
                        .font(.body)
                        .foregroundStyle(AppColors.primaryText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(20)
                }
                .background(AppColors.page)
                .navigationTitle(L10n.string(titleKey))
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button(L10n.string("Закрыть")) {
                            isPresented = false
                        }
                    }
                }
            }
            .preferredColorScheme(.dark)
            .presentationDetents([.medium, .large])
        }
    }
}

struct HarmonyTempoSlider: View {
    @Binding var bpm: Double

    var body: some View {
        HStack(spacing: 12) {
            Text("Темп")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(AppColors.primaryText)

            Text("40")
                .font(.caption.monospacedDigit())
                .foregroundStyle(AppColors.mutedText)

            Slider(value: $bpm, in: 40...200, step: 5)
                .tint(AppColors.rootText)

            Text("200")
                .font(.caption.monospacedDigit())
                .foregroundStyle(AppColors.mutedText)

            Text("\(Int(bpm)) BPM")
                .font(.caption.weight(.bold).monospacedDigit())
                .foregroundStyle(AppColors.primaryText)
                .frame(width: 66, alignment: .trailing)
        }
        .padding(.horizontal, 12)
        .frame(minHeight: 42)
        .appSurface(fill: AppColors.control.opacity(0.72))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(L10n.string("Темп")) \(Int(bpm)) BPM")
    }
}

struct DegreeChordOption: Hashable {
    let degree: Int
    let kind: FunctionalChordKind
}

struct DegreeSquarePicker: View {
    let index: Int
    let degree: Int
    let function: String
    let degreeTitle: String
    let chordName: String
    var portraitChordFontSize: CGFloat = 26
    let color: Color
    let options: [MenuPickerItem<DegreeChordOption>]
    let onSelect: (DegreeChordOption) -> Void

    @Environment(\.verticalSizeClass) private var verticalSizeClass

    private var isPortrait: Bool { verticalSizeClass != .compact }

    var body: some View {
        Menu {
            ForEach(options) { option in
                Button(option.title) {
                    onSelect(option.value)
                }
            }
        } label: {
            ZStack {
                VStack(spacing: isPortrait ? 5 : 10) {
                    Text(chordName)
                        .font(.system(size: isPortrait ? portraitChordFontSize : 42, weight: .black, design: .rounded))
                        .minimumScaleFactor(0.55)
                        .lineLimit(1)
                    Text("\(degree) / \(degreeTitle)")
                        .font(isPortrait ? .subheadline.weight(.heavy) : .title3.weight(.heavy))
                        .minimumScaleFactor(0.6)
                        .lineLimit(1)
                }
                .padding(.horizontal, isPortrait ? 4 : 10)
                .foregroundStyle(.white)

                VStack {
                    Text(function)
                        .font(isPortrait ? .caption.weight(.black) : .title3.weight(.black))
                        .foregroundStyle(.white.opacity(0.82))
                    Spacer()
                }
                .padding(.top, isPortrait ? 6 : 12)
            }
            .frame(maxWidth: .infinity)
            .aspectRatio(1, contentMode: .fit)
            .background(color.opacity(0.84), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Color.white.opacity(0.16), lineWidth: 1)
            }
            .shadow(color: color.opacity(0.18), radius: 8, y: 4)
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
        .accessibilityLabel("\(index + 1): \(chordName), \(L10n.string("Ступени")) \(degree)")
    }
}

struct RatingMeter: View {
    @Binding var value: Int

    var body: some View {
        HStack(spacing: 4) {
            ForEach(1...5, id: \.self) { index in
                Button {
                    value = index
                } label: {
                    Capsule()
                        .fill(index <= value ? progressionRatingColor(for: value) : AppColors.control)
                        .frame(width: 14, height: 6)
                        .frame(width: 20, height: 30)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Рейтинг \(index) из 5")
            }
        }
    }
}

func progressionRatingColor(for rating: Int) -> Color {
    switch rating {
    case 1:
        Color(red: 0.43, green: 0.08, blue: 0.15)
    case 2:
        HarmonyColor.red.color
    case 4:
        HarmonyColor.yellow.color
    case 5:
        HarmonyColor.green.color
    default:
        AppColors.mutedText
    }
}

struct DegreeChip: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.title3.weight(.black))
            .foregroundStyle(.white)
            .frame(width: 66, height: 44)
            .background(color, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}
