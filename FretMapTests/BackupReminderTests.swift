import XCTest
@testable import FretMap

final class BackupReminderTests: XCTestCase {
    func testReadsExpirationFromWrappedProfile() throws {
        let expiry = Date(timeIntervalSince1970: 2000000000)
        let plist = try PropertyListSerialization.data(fromPropertyList: ["ExpirationDate": expiry], format: .xml, options: 0)
        let wrapped = Data([0x30, 0x82, 0xff]) + plist + Data([0, 0xff])
        XCTAssertEqual(BackupReminderSchedule.expiration(in: wrapped), expiry)
        XCTAssertNil(BackupReminderSchedule.expiration(in: Data("invalid".utf8)))
    }

    func testSchedulingBeforeExpiryAndLateInstallation() {
        let now = Date(timeIntervalSince1970: 2000000000)
        XCTAssertEqual(BackupReminderSchedule.fireDate(expiration: now.addingTimeInterval(7 * 86400), now: now), now.addingTimeInterval(6 * 86400))
        XCTAssertEqual(BackupReminderSchedule.fireDate(expiration: now.addingTimeInterval(3600), now: now), now.addingTimeInterval(60))
        XCTAssertNil(BackupReminderSchedule.fireDate(expiration: now, now: now))
    }
}
