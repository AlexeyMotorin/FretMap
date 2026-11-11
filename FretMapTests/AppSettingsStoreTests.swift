import XCTest
@testable import FretMap

final class AppSettingsStoreTests: XCTestCase {
    func testSettingsPersistAcrossStoreInstances() async {
        await MainActor.run {
            let persistence = InMemorySettingsPersistence()
            let firstStore = AppSettingsStore(persistence: persistence)

            firstStore.rootNote = 9
            firstStore.stringCount = 7
            firstStore.harmonyTempoBPM = 148
            firstStore.favoriteProgressionIDs = ["progression-a"]

            let restoredStore = AppSettingsStore(persistence: persistence)

            XCTAssertEqual(restoredStore.rootNote, 9)
            XCTAssertEqual(restoredStore.stringCount, 7)
            XCTAssertEqual(restoredStore.harmonyTempoBPM, 148)
            XCTAssertEqual(restoredStore.favoriteProgressionIDs, ["progression-a"])
        }
    }

    func testInvalidValuesAreNormalized() async {
        await MainActor.run {
            let store = AppSettingsStore(persistence: InMemorySettingsPersistence())

            store.rootNote = 99
            store.stringCount = 2
            store.chordStringCount = 12
            store.harmonyTempoBPM = 500
            store.functionalSelectedDegrees = [0, 8]
            store.popularGlobalRoot = -8
            store.popularProgressionRoots = ["invalid-high": 99, "invalid-low": -3]
            store.favoriteProgressionIDs = ["progression-b", "progression-a", "progression-b"]
            store.normalize()

            XCTAssertEqual(store.rootNote, 11)
            XCTAssertEqual(store.stringCount, 4)
            XCTAssertEqual(store.chordStringCount, 8)
            XCTAssertEqual(store.harmonyTempoBPM, 200)
            XCTAssertEqual(store.functionalSelectedDegrees.count, 8)
            XCTAssertTrue(store.functionalSelectedDegrees.allSatisfy { (1...7).contains($0) })
            XCTAssertEqual(store.popularGlobalRoot, -1)
            XCTAssertEqual(store.popularProgressionRoots["invalid-high"], 11)
            XCTAssertEqual(store.popularProgressionRoots["invalid-low"], -1)
            XCTAssertEqual(store.favoriteProgressionIDs, ["progression-b", "progression-a"])
        }
    }

    func testNormalizePersistsOnce() async {
        await MainActor.run {
            let persistence = InMemorySettingsPersistence()
            let store = AppSettingsStore(persistence: persistence)
            store.rootNote = 99
            store.stringCount = 2
            let writesBeforeNormalize = persistence.writeCount

            store.normalize()

            XCTAssertEqual(persistence.writeCount, writesBeforeNormalize + 1)
        }
    }
}
