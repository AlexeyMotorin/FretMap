import SwiftUI

struct MasteryResultDetails: View {
    let result: MasteryResult

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let subdivision = result.subdivision {
                Text(L10n.string(subdivision.localizationKey))
            }
            if let repetitions = result.cleanRepetitions {
                Text("\(L10n.string("mastery.repetitions")): \(repetitions)")
            }
            if let difficulty = result.difficulty {
                Text(L10n.string(difficulty.localizationKey))
            }
        }.font(.caption).foregroundStyle(.secondary)
    }
}
