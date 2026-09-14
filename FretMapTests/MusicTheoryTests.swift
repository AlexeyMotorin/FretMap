import XCTest
@testable import FretMap

final class MusicTheoryTests: XCTestCase {
    func testDiatonicSpellingUsesTheCorrectLetterForEveryDegree() {
        let sharps = AccidentalStyle.sharps.noteNames
        let flats = AccidentalStyle.flats.noteNames

        XCTAssertEqual(
            MusicNoteSpeller.noteName(pitchClass: 10, tonicPitchClass: 5, degree: 4, preferredNames: sharps),
            "Bb"
        )
        XCTAssertEqual(
            MusicNoteSpeller.noteName(pitchClass: 5, tonicPitchClass: 6, degree: 7, preferredNames: sharps),
            "E#"
        )
        XCTAssertEqual(
            MusicNoteSpeller.noteName(pitchClass: 11, tonicPitchClass: 6, degree: 4, preferredNames: flats),
            "Cb"
        )
    }

    func testChromaticScaleUsesTheSelectedAccidentalStyleWithoutDoubleAccidentals() {
        let tonic = 10

        let sharpNames = (0..<12).map { interval in
            MusicNoteSpeller.scaleNoteName(
                pitchClass: tonic + interval,
                tonicPitchClass: tonic,
                scale: .chromatic,
                preferredNames: AccidentalStyle.sharps.noteNames
            )
        }
        XCTAssertEqual(sharpNames, ["A#", "B", "C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A"])

        let flatNames = (0..<12).map { interval in
            MusicNoteSpeller.scaleNoteName(
                pitchClass: tonic + interval,
                tonicPitchClass: tonic,
                scale: .chromatic,
                preferredNames: AccidentalStyle.flats.noteNames
            )
        }
        XCTAssertEqual(flatNames, ["Bb", "B", "C", "Db", "D", "Eb", "E", "F", "Gb", "G", "Ab", "A"])
    }

    func testRomanDegreesAreMeasuredAgainstParallelMajor() {
        XCTAssertEqual(HarmonyTheory.pitchClass(for: "#iv°", tonicPitchClass: 0), 6)
        XCTAssertEqual(HarmonyTheory.pitchClass(for: "bVII", tonicPitchClass: 0), 10)
        XCTAssertEqual(HarmonyTheory.pitchClass(for: "bvii", tonicPitchClass: 4), 2)
    }

    func testChordExtensionsUseLeadSheetNotation() {
        let dominantFlatNine = ChordSettings(
            quality: .major,
            size: .dominantSeventh,
            extensions: [.flat9]
        )
        let dominantThirteen = ChordSettings(
            quality: .major,
            size: .dominantSeventh,
            extensions: [.thirteenth]
        )
        let triadThirteen = ChordSettings(
            quality: .major,
            size: .triad,
            extensions: [.thirteenth]
        )

        XCTAssertEqual(dominantFlatNine.displaySuffix, "7(b9)")
        XCTAssertEqual(dominantThirteen.displaySuffix, "7(13)")
        XCTAssertTrue(dominantThirteen.intervals.isSuperset(of: [0, 4, 7, 9, 10]))
        XCTAssertEqual(triadThirteen.displaySuffix, "")
        XCTAssertFalse(triadThirteen.intervals.contains(9))
    }

    func testFunctionalMinorUsesLeadingToneDominants() {
        XCTAssertEqual(FunctionalKeyMode.minor.intervals[6], 11)
        XCTAssertEqual(FunctionalKeyMode.minor.qualities[4], "")
        XCTAssertEqual(FunctionalKeyMode.minor.qualities[6], "dim")
        XCTAssertEqual(FunctionalKeyMode.minor.degreeTitles[4], "V")
        XCTAssertEqual(FunctionalKeyMode.minor.degreeTitles[6], "vii°")
    }

    func testModalRomanNumeralsAndQualitiesAreConsistent() {
        XCTAssertEqual(ModalBuilderMode.phrygian.cells[4].degree, "v°")
        XCTAssertEqual(ModalBuilderMode.phrygian.cells[6].degree, "bvii")
        XCTAssertEqual(ModalBuilderMode.locrian.cells[6].degree, "bvii")
        XCTAssertEqual(ModalBuilderMode.locrian.cells[6].chord, "m")
        XCTAssertEqual(ModalBuilderMode.lydian.cells[3].degree, "#iv°")
    }

    func testDiatonicPopularProgressionsMatchTheirDeclaredModes() throws {
        for progression in MusicDatabase.allPopularProgressions where !progression.usesBorrowedHarmony {
            for degree in progression.degrees {
                let chordDegree = String(degree.split(separator: "/", maxSplits: 1)[0])
                let index = try XCTUnwrap(HarmonyTheory.degreeIndex(for: chordDegree))
                let actualPitch = try XCTUnwrap(HarmonyTheory.pitchClass(for: chordDegree, tonicPitchClass: 0))
                XCTAssertEqual(
                    actualPitch,
                    progression.scale.intervals[index],
                    "\(progression.id) has a non-diatonic root at \(degree)"
                )

                let expectedQuality = diatonicTriadQuality(scale: progression.scale, degreeIndex: index)
                XCTAssertEqual(
                    romanTriadQuality(chordDegree),
                    expectedQuality,
                    "\(progression.id) has the wrong triad quality at \(degree)"
                )
            }
        }
    }

    private func diatonicTriadQuality(scale: ScalePattern, degreeIndex: Int) -> String {
        let root = scale.intervals[degreeIndex]
        let thirdIndex = (degreeIndex + 2) % 7
        let fifthIndex = (degreeIndex + 4) % 7
        let third = (scale.intervals[thirdIndex] + (thirdIndex < degreeIndex ? 12 : 0)) - root
        let fifth = (scale.intervals[fifthIndex] + (fifthIndex < degreeIndex ? 12 : 0)) - root
        switch (third, fifth) {
        case (4, 7): return "major"
        case (3, 7): return "minor"
        case (3, 6): return "diminished"
        default: return "other"
        }
    }

    private func romanTriadQuality(_ degree: String) -> String {
        if degree.contains("°") {
            return "diminished"
        }
        return HarmonyTheory.romanToken(from: degree).first?.isLowercase == true ? "minor" : "major"
    }
}
