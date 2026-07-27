import Foundation

struct ChordShapeGenerator {
    let settings: ChordSettings
    let tuning: TuningPreset
    let fretCount: Int
    let stringCount: Int

    var supportsCAGEDShapes: Bool {
        let standardTopSix = [4, 9, 2, 7, 11, 4]
        return tuning.strings.suffix(6).map(\.pitchClass) == standardTopSix
    }

    func generateShapes() -> [ChordShape] {
        guard stringCount >= 4 else { return [] }
        return Array((4...stringCount).reversed()).compactMap(generateShape)
    }

    private func generateShape(rootString: Int) -> ChordShape? {
        let displayedStrings = Array(tuning.strings.reversed())
        let rootIndex = rootString - 1
        guard displayedStrings.indices.contains(rootIndex) else { return nil }

        let maxRootFret = min(fretCount, 12)
        guard let rootFret = (0...maxRootFret).first(where: {
            (displayedStrings[rootIndex].pitchClass + $0) % 12 == settings.root
        }) else {
            return nil
        }

        let allowedIntervals = settings.intervals
        let stringNumbers = Array(max(1, rootString - 4)...rootString)
        var notes = [ChordShape.Note(stringNumber: rootString, fret: rootFret)]
        var coveredIntervals: Set<Int> = [0]

        for stringNumber in stringNumbers where stringNumber != rootString {
            guard let note = bestNote(
                stringNumber: stringNumber,
                rootFret: rootFret,
                coveredIntervals: coveredIntervals,
                displayedStrings: displayedStrings,
                allowedIntervals: allowedIntervals
            ) else {
                continue
            }

            let pitch = (displayedStrings[stringNumber - 1].pitchClass + note.fret) % 12
            let interval = (pitch - settings.root + 12) % 12
            notes.append(note)
            coveredIntervals.insert(interval)
        }

        guard settings.requiredIntervals.isSubset(of: coveredIntervals) else {
            return nil
        }

        return ChordShape(
            id: shapeID(rootString: rootString, rootFret: rootFret),
            title: "Кастом от \(rootString) струны",
            quality: settings.quality,
            size: settings.size,
            rootString: rootString,
            baseRoot: settings.root,
            notes: notes.sorted { $0.stringNumber < $1.stringNumber },
            barres: []
        )
    }

    private func bestNote(
        stringNumber: Int,
        rootFret: Int,
        coveredIntervals: Set<Int>,
        displayedStrings: [GuitarString],
        allowedIntervals: Set<Int>
    ) -> ChordShape.Note? {
        let stringIndex = stringNumber - 1
        guard displayedStrings.indices.contains(stringIndex) else { return nil }

        let startFret = max(0, rootFret - 2)
        let endFret = min(fretCount, rootFret + 5)
        let candidates = (startFret...endFret).compactMap { fret -> Candidate? in
            let pitch = (displayedStrings[stringIndex].pitchClass + fret) % 12
            let interval = (pitch - settings.root + 12) % 12
            guard allowedIntervals.contains(interval) else { return nil }

            let duplicatePenalty = coveredIntervals.contains(interval) ? 80 : 0
            let distancePenalty = abs(fret - rootFret) * 4
            let openStringBonus = fret == 0 ? -3 : 0
            return Candidate(
                note: ChordShape.Note(stringNumber: stringNumber, fret: fret),
                score: duplicatePenalty + distancePenalty + openStringBonus
            )
        }

        return candidates.min { $0.score < $1.score }?.note
    }

    private func shapeID(rootString: Int, rootFret: Int) -> String {
        let extensions = settings.extensions.map(\.rawValue).joined(separator: "-")
        return [
            "generated",
            "\(settings.root)",
            settings.quality.rawValue,
            settings.size.rawValue,
            extensions,
            "\(rootString)",
            "\(rootFret)"
        ]
        .joined(separator: "-")
    }
}

private extension ChordShapeGenerator {
    struct Candidate {
        let note: ChordShape.Note
        let score: Int
    }
}
