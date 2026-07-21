//
//  FretMapApp.swift
//  FretMap
//
//  Created by Алексей Моторин on 7/3/26.
//

import SwiftUI
import UIKit
import OSLog

final class AppDelegate: NSObject, UIApplicationDelegate {
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
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
