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

        #if !targetEnvironment(macCatalyst)
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
        #endif
    }
}

@main
struct FretMapApp: App {
    #if targetEnvironment(macCatalyst)
    @StateObject private var settings = AppSettingsStore()
    #endif
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup {
            #if targetEnvironment(macCatalyst)
            ContentView(store: settings)
                .background(MacWindowSizeSetup(minimumSize: CGSize(width: 1040, height: 680)).allowsHitTesting(false))
                .modifier(MainWindowLifecycle())
                .modifier(MacAppLanguage())
            #else
            ContentView()
                .modifier(MainWindowLifecycle())
            #endif
        }
        #if targetEnvironment(macCatalyst)
        WindowGroup("mac.fretboard.window", id: "scale-fretboard") {
            HomeCoordinatorView(store: settings, customTuningTargetMode: .constant(nil),
                                isCreatingSavedProgression: .constant(false), standaloneFretboard: true)
                .background(MacWindowSizeSetup(minimumSize: CGSize(width: 1280, height: 480),
                                               title: L10n.string("mac.fretboard.window")).allowsHitTesting(false))
                .modifier(MacAppLanguage())
        }
        #endif
    }
}

#if targetEnvironment(macCatalyst)
private struct MacAppLanguage: ViewModifier {
    @AppStorage(SupportedAppLanguage.preferenceKey) private var language = ""
    @Environment(\.layoutDirection) private var systemLayoutDirection

    func body(content: Content) -> some View {
        let selected = SupportedAppLanguage.resolved(language)
        content
            .environment(\.locale, selected?.locale ?? .autoupdatingCurrent)
            .environment(\.layoutDirection, selected.map { $0 == .arabic ? .rightToLeft : .leftToRight } ?? systemLayoutDirection)
            .id(language)
    }
}

private struct MacWindowSizeSetup: UIViewRepresentable {
    let minimumSize: CGSize
    var title: String?

    final class WindowView: UIView {
        var minimumSize: CGSize = .zero
        var sceneTitle: String?

        override func didMoveToWindow() {
            super.didMoveToWindow()
            applyRestrictions()
        }

        func applyRestrictions() {
            guard let scene = window?.windowScene else { return }
            if let sceneTitle { scene.title = sceneTitle }
            // Apply only to the hosting scene; the main window must not reset
            // the detached fretboard's minimum when it becomes visible again.
            scene.sizeRestrictions?.minimumSize = minimumSize
            scene.sizeRestrictions?.allowsFullScreen = true
        }
    }

    func makeUIView(context: Context) -> WindowView {
        let view = WindowView()
        view.minimumSize = minimumSize
        view.sceneTitle = title
        return view
    }

    func updateUIView(_ uiView: WindowView, context: Context) {
        uiView.minimumSize = minimumSize
        uiView.sceneTitle = title
        uiView.applyRestrictions()
    }
}
#endif

private struct MainWindowLifecycle: ViewModifier {
    @Environment(\.scenePhase) private var scenePhase
    func body(content: Content) -> some View {
        content
                .task { await BackupReminder.shared.refresh() }
                .onChange(of: scenePhase) { phase in
                    if phase == .active { Task { await BackupReminder.shared.refresh() } }
                }
    }
}
