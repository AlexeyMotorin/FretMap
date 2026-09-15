import Foundation
import Combine
import UserNotifications
import SwiftUI

// The embedded profile is CMS-wrapped. Read only its XML plist payload;
// this is a reminder hint, not a code-signature validation.
nonisolated enum BackupReminderSchedule {
    static func expiration(in data: Data) -> Date? {
        guard let start = data.range(of: Data("<?xml".utf8)),
              let end = data.range(of: Data("</plist>".utf8), in: start.lowerBound..<data.endIndex),
              let plist = try? PropertyListSerialization.propertyList(
                from: data.subdata(in: start.lowerBound..<end.upperBound), format: nil),
              let values = plist as? [String: Any] else { return nil }
        return values["ExpirationDate"] as? Date
    }

    static func fireDate(expiration: Date, now: Date) -> Date? {
        guard expiration.timeIntervalSince(now) > 60 else { return nil }
        return max(expiration.addingTimeInterval(-86400), now.addingTimeInterval(60))
    }
}

@MainActor
final class BackupReminder: ObservableObject {
    static let shared = BackupReminder()
    private let identifier = "fretmap.backup.before-expiration"
    @Published private(set) var status = "backup.reminder.unknown"
    @Published private(set) var expiration: Date?
    private var updating = false

    func refresh() async {
        guard !updating else { return }
        updating = true
        defer { updating = false }
        let center = UNUserNotificationCenter.current()
        guard let url = Bundle.main.url(forResource: "embedded", withExtension: "mobileprovision"),
              let data = try? Data(contentsOf: url),
              let expiry = BackupReminderSchedule.expiration(in: data) else {
            expiration = nil
            status = "backup.reminder.unknown"
            center.removePendingNotificationRequests(withIdentifiers: [identifier])
            return
        }
        expiration = expiry
        var settings = await center.notificationSettings()
        if settings.authorizationStatus == .notDetermined {
            do { _ = try await center.requestAuthorization(options: [.alert, .sound]) }
            catch { status = "backup.reminder.error"; return }
            settings = await center.notificationSettings()
        }
        guard settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional else {
            status = "backup.reminder.denied"
            center.removePendingNotificationRequests(withIdentifiers: [identifier])
            return
        }
        let now = Date()
        guard let date = BackupReminderSchedule.fireDate(expiration: expiry, now: now) else {
            status = "backup.reminder.expired"
            center.removePendingNotificationRequests(withIdentifiers: [identifier])
            return
        }
        let key = "backup.reminder.scheduledExpiration"
        let pending = await center.pendingNotificationRequests()
        // Do not keep postponing an imminent reminder or repeat one already delivered.
        if UserDefaults.standard.object(forKey: key) as? Date == expiry,
           pending.contains(where: { $0.identifier == identifier }) || now >= expiry.addingTimeInterval(-86400) {
            status = "backup.reminder.enabled"
            return
        }
        let content = UNMutableNotificationContent()
        content.title = L10n.string("backup.reminder.title")
        content.body = L10n.string("backup.reminder.body")
        content.sound = .default
        let components = Calendar.current.dateComponents([.calendar, .timeZone, .year, .month, .day, .hour, .minute, .second], from: date)
        let request = UNNotificationRequest(identifier: identifier, content: content,
            trigger: UNCalendarNotificationTrigger(dateMatching: components, repeats: false))
        do {
            try await center.add(request)
            UserDefaults.standard.set(expiry, forKey: key)
            status = "backup.reminder.enabled"
        } catch { status = "backup.reminder.error" }
    }
}
