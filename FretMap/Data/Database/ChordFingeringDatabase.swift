import Foundation

enum ChordFingeringDatabase {
    static let all: [ChordShape] = [
        shape("major-e", "E-shape баррэ", .major, .triad, 6, 7, [
            n(1, 3), n(2, 3), n(3, 4), n(4, 5), n(5, 5), n(6, 3)
        ], [b(3, 1, 6)]),
        shape("major-d", "D-shape", .major, .triad, 4, 7, [
            n(1, 7), n(2, 8), n(3, 7), n(4, 5)
        ]),
        shape("major-c", "C-shape баррэ", .major, .triad, 5, 7, [
            n(1, 7), n(2, 8), n(3, 7), n(4, 9), n(5, 10)
        ], [b(7, 1, 3)]),
        shape("major-a", "A-shape баррэ", .major, .triad, 5, 7, [
            n(1, 10), n(2, 12), n(3, 12), n(4, 12), n(5, 10)
        ], [b(10, 1, 5)]),

        shape("minor-e", "E-shape баррэ", .minor, .triad, 6, 7, [
            n(1, 3), n(2, 3), n(3, 3), n(4, 5), n(5, 5), n(6, 3)
        ], [b(3, 1, 6)]),
        shape("minor-d", "D-shape", .minor, .triad, 4, 7, [
            n(1, 6), n(2, 8), n(3, 7), n(4, 5)
        ]),
        shape("minor-a", "A-shape баррэ", .minor, .triad, 5, 7, [
            n(1, 10), n(2, 11), n(3, 12), n(4, 12), n(5, 10)
        ], [b(10, 1, 5)]),

        shape("dim-six", "Dim от 6 струны", .diminished, .triad, 6, 7, [
            n(3, 3), n(4, 5), n(5, 4), n(6, 3)
        ], [b(3, 3, 6)]),
        shape("dim-four", "Dim от 4 струны", .diminished, .triad, 4, 7, [
            n(1, 6), n(2, 5), n(3, 6), n(4, 5)
        ]),
        shape("dim-five", "Dim от 5 струны", .diminished, .triad, 5, 7, [
            n(2, 11), n(3, 12), n(4, 11), n(5, 10)
        ]),

        shape("maj7-six", "maj7", .major, .majorSeventh, 6, 7, [
            n(2, 3), n(3, 4), n(4, 4), n(6, 3)
        ]),
        shape("maj7-five", "maj7", .major, .majorSeventh, 5, 7, [
            n(2, 12), n(3, 11), n(4, 12), n(5, 10)
        ]),
        shape("maj7-four", "maj7", .major, .majorSeventh, 4, 7, [
            n(1, 2), n(2, 3), n(3, 4), n(4, 5)
        ]),

        shape("dom7-six", "7 баррэ", .major, .dominantSeventh, 6, 7, [
            n(1, 3), n(2, 3), n(3, 4), n(4, 3), n(5, 5), n(6, 3)
        ], [b(3, 1, 6)]),
        shape("dom7-five", "7", .major, .dominantSeventh, 5, 7, [
            n(2, 8), n(3, 10), n(4, 9), n(5, 10)
        ]),
        shape("dom7-four", "7", .major, .dominantSeventh, 4, 7, [
            n(1, 7), n(2, 6), n(3, 7), n(4, 5)
        ]),

        shape("m7-six", "m7 баррэ", .minor, .minorSeventh, 6, 7, [
            n(1, 3), n(2, 3), n(3, 3), n(4, 3), n(5, 5), n(6, 3)
        ], [b(3, 1, 6)]),
        shape("m7-five", "m7", .minor, .minorSeventh, 5, 7, [
            n(1, 10), n(2, 11), n(3, 10), n(4, 12), n(5, 10)
        ]),
        shape("m7-four", "m7", .minor, .minorSeventh, 4, 7, [
            n(1, 6), n(2, 6), n(3, 7), n(4, 5)
        ]),

        shape("m7b5-six", "m7b5", .diminished, .halfDiminished, 6, 7, [
            n(2, 2), n(3, 3), n(4, 3), n(6, 3)
        ]),
        shape("m7b5-five", "m7b5", .diminished, .halfDiminished, 5, 7, [
            n(2, 11), n(3, 10), n(4, 11), n(5, 10)
        ]),
        shape("m7b5-four", "m7b5", .diminished, .halfDiminished, 4, 7, [
            n(1, 6), n(2, 6), n(3, 6), n(4, 5)
        ]),

        shape("major-seven-string", "От 7 струны", .major, .triad, 7, 7, [
            n(3, 7), n(4, 9), n(5, 10), n(6, 7), n(7, 8)
        ]),
        shape("minor-seven-string", "От 7 струны", .minor, .triad, 7, 7, [
            n(3, 7), n(4, 8), n(5, 10), n(6, 6), n(7, 8)
        ]),
        shape("aug-seven-string", "От 7 струны", .augmented, .triad, 7, 7, [
            n(4, 9), n(5, 11), n(6, 7), n(7, 8)
        ]),
        shape("dim-seven-string", "От 7 струны", .diminished, .triad, 7, 7, [
            n(4, 8), n(5, 9), n(6, 6), n(7, 8)
        ]),
        shape("maj7-seven-string", "maj7 от 7 струны", .major, .majorSeventh, 7, 7, [
            n(3, 7), n(4, 9), n(5, 9), n(6, 7), n(7, 8)
        ]),
        shape("dom7-seven-string", "7 от 7 струны", .major, .dominantSeventh, 7, 7, [
            n(3, 7), n(4, 9), n(5, 8), n(6, 7), n(7, 8)
        ]),
        shape("m7-seven-string", "m7 от 7 струны", .minor, .minorSeventh, 7, 7, [
            n(3, 7), n(4, 8), n(5, 8), n(6, 6), n(7, 8)
        ]),
        shape("m7b5-seven-string", "m7b5 от 7 струны", .diminished, .halfDiminished, 7, 7, [
            n(3, 10), n(4, 8), n(5, 9), n(6, 6), n(7, 8)
        ]),

        shape("major-eight-string", "От 8 струны", .major, .triad, 8, 7, [
            n(4, 5), n(5, 2), n(6, 3), n(7, 3), n(8, 1)
        ]),
        shape("minor-eight-string", "От 8 струны", .minor, .triad, 8, 7, [
            n(4, 5), n(5, 1), n(6, 3), n(7, 3), n(8, 1)
        ]),
        shape("aug-eight-string", "От 8 струны", .augmented, .triad, 8, 7, [
            n(5, 2), n(6, 3), n(7, 4), n(8, 1)
        ]),
        shape("dim-eight-string", "От 8 струны", .diminished, .triad, 8, 7, [
            n(5, 1), n(6, 3), n(7, 2), n(8, 1)
        ]),
        shape("maj7-eight-string", "maj7 от 8 струны", .major, .majorSeventh, 8, 7, [
            n(4, 5), n(5, 2), n(6, 2), n(7, 3), n(8, 1)
        ]),
        shape("dom7-eight-string", "7 от 8 струны", .major, .dominantSeventh, 8, 7, [
            n(4, 3), n(5, 2), n(6, 1), n(7, 3), n(8, 1)
        ]),
        shape("m7-eight-string", "m7 от 8 струны", .minor, .minorSeventh, 8, 7, [
            n(4, 3), n(5, 1), n(6, 1), n(7, 3), n(8, 1)
        ]),
        shape("m7b5-eight-string", "m7b5 от 8 струны", .diminished, .halfDiminished, 8, 7, [
            n(4, 3), n(5, 1), n(6, 1), n(7, 2), n(8, 1)
        ])
    ]

    static func shapes(quality: ChordQuality, size: ChordSize, maxRootString: Int) -> [ChordShape] {
        all.filter { shape in
            shape.quality == quality &&
            shape.size == size &&
            shape.rootString <= maxRootString
        }
    }

    private static func shape(
        _ id: String,
        _ title: String,
        _ quality: ChordQuality,
        _ size: ChordSize,
        _ rootString: Int,
        _ baseRoot: Int,
        _ notes: [ChordShape.Note],
        _ barres: [ChordBarre] = []
    ) -> ChordShape {
        ChordShape(
            id: id,
            title: title,
            quality: quality,
            size: size,
            rootString: rootString,
            baseRoot: baseRoot,
            notes: notes,
            barres: barres
        )
    }

    private static func n(_ stringNumber: Int, _ fret: Int) -> ChordShape.Note {
        ChordShape.Note(stringNumber: stringNumber, fret: fret)
    }

    private static func b(_ fret: Int, _ fromStringNumber: Int, _ toStringNumber: Int) -> ChordBarre {
        ChordBarre(fret: fret, fromStringNumber: fromStringNumber, toStringNumber: toStringNumber)
    }
}
