//
//  FretMapApp.swift
//  FretMap
//
//  Created by Алексей Моторин on 7/3/26.
//

import SwiftUI
import UIKit
import OSLog
import UserNotifications

final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .list, .sound])
    }

    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        AppOrientationController.supportedOrientations
    }
}

enum AppOrientationController {
    static var supportedOrientations: UIInterfaceOrientationMask = .allButUpsideDown

    static func setSupportedOrientations(_ orientations: UIInterfaceOrientationMask) {
        supportedOrientations = orientations

        guard let windowScene = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first else {
            return
        }

        windowScene.windows.first(where: \.isKeyWindow)?.rootViewController?.setNeedsUpdateOfSupportedInterfaceOrientations()

        guard orientations != .allButUpsideDown else {
            return
        }

        windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: orientations)) { error in
            AppLogger.orientation.error("Failed to update interface orientation: \(error.localizedDescription, privacy: .public)")
        }
    }
}

@main
struct FretMapApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
                .task { await BackupReminder.shared.refresh() }
                .onChange(of: scenePhase) { phase in
                    if phase == .active { Task { await BackupReminder.shared.refresh() } }
                }
        }
    }
}
