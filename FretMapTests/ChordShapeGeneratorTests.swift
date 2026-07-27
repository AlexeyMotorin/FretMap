import XCTest
@testable import FretMap

final class ChordShapeGeneratorTests: XCTestCase {
    func testGeneratedShapesOnlyUseChordIntervals() {
        let settings = ChordSettings(
            root: 0,
            quality: .major,
            size: .triad
        )
        let generator = ChordShapeGenerator(
            settings: settings,
            tuning: .standard6,
            fretCount: 24,
            stringCount: 6
        )

        let shapes = generator.generateShapes()
        let displayedStrings = Array(TuningPreset.standard6.strings.reversed())

        XCTAssertFalse(shapes.isEmpty)
        for shape in shapes {
            for note in shape.notes {
                let guitarString = displayedStrings[note.stringNumber - 1]
                let pitchClass = (guitarString.pitchClass + note.fret) % 12
                XCTAssertTrue(settings.intervals.contains(pitchClass))
            }
        }
    }

    func testStandardSixStringTuningSupportsCAGED() {
        let generator = ChordShapeGenerator(
            settings: ChordSettings(),
            tuning: .standard6,
            fretCount: 24,
            stringCount: 6
        )

        XCTAssertTrue(generator.supportsCAGEDShapes)
    }
}
