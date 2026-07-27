import SwiftUI

struct CustomChordEditorView: View {
    @ObservedObject var store: AppSettingsStore
    let tuning: TuningPreset
    let fretCount: Int
    let noteNames: [String]
    let onDismiss: () -> Void

    var body: some View {
        ZStack(alignment: .topLeading) {
            FretboardView(
                tuning: tuning,
                fretCount: fretCount,
                visibleFretRange: 0...min(fretCount, 12),
                markers: [],
                barres: [],
                selectedPositions: store.customPositions,
                selectedPositionLabels: positionLabels,
                customMode: true,
                onTapPosition: togglePosition,
                onSwipe: nil
            )

            Button(action: onDismiss) {
                Label("Назад", systemImage: "chevron.left")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(AppColors.primaryText)
                    .padding(.horizontal, 14)
                    .frame(height: 44)
                    .background(
                        AppColors.panel.opacity(0.95),
                        in: RoundedRectangle(cornerRadius: 8, style: .continuous)
                    )
            }
            .buttonStyle(.plain)
            .padding(12)

            if let chordName = identifiedChord {
                Text(chordName)
                    .font(.title3.weight(.black))
                    .foregroundStyle(AppColors.primaryText)
                    .padding(.horizontal, 16)
                    .frame(height: 44)
                    .background(
                        AppColors.panel.opacity(0.95),
                        in: RoundedRectangle(cornerRadius: 8, style: .continuous)
                    )
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(12)
                    .allowsHitTesting(false)
            }
        }
        .background(AppColors.fretboard)
    }

    private var displayedStrings: [GuitarString] {
        Array(tuning.strings.reversed())
    }

    private var positionLabels: [FretPosition: String] {
        Dictionary(uniqueKeysWithValues: store.customPositions.compactMap { position in
            guard displayedStrings.indices.contains(position.stringIndex) else { return nil }
            let pitch = (displayedStrings[position.stringIndex].pitchClass + position.fret) % 12
            return (position, noteNames[pitch])
        })
    }

    private var identifiedChord: String? {
        let pitches = Set(store.customPositions.compactMap { position -> Int? in
            guard displayedStrings.indices.contains(position.stringIndex) else { return nil }
            return (displayedStrings[position.stringIndex].pitchClass + position.fret) % 12
        })
        return ChordIdentifier.identify(pitchClasses: pitches, noteNames: noteNames)
    }

    private func togglePosition(_ position: FretPosition) {
        withoutAnimation {
            if store.customPositions.contains(position) {
                store.customPositions.remove(position)
            } else {
                store.customPositions = Set(
                    store.customPositions.filter { $0.stringIndex != position.stringIndex }
                )
                store.customPositions.insert(position)
            }
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
