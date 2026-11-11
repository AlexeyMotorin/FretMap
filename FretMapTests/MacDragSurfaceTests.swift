#if targetEnvironment(macCatalyst)
import XCTest
import SwiftUI
@testable import FretMap

final class MacDragSurfaceTests: XCTestCase {
    @MainActor func testMaterialsDropIsOnTheHitTestedViewNotTheWindow() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = MasteryStore(directory: directory)
        let song = MasterySong(title: "Drop", artist: "Test")
        XCTAssertTrue(store.save(song))
        let content = MacMaterialsPanel(store: store, target: .song(song.id), isImporting: .constant(false), addingLink: .constant(false))
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 800, height: 600))
        let host = UIHostingController(rootView: content)
        window.rootViewController = host
        window.makeKeyAndVisible()
        defer { window.isHidden = true; window.rootViewController = nil }
        host.view.layoutIfNeeded()
        try await Task.sleep(nanoseconds: 1_000_000_000)
        let surface = try XCTUnwrap(descendants(host.view).first { view in
            view.accessibilityIdentifier == "mac.materials.dropSurface"
        })
        XCTAssertGreaterThan(surface.bounds.width, 100)
        XCTAssertGreaterThanOrEqual(surface.bounds.height, 54)
        let center = CGPoint(x: surface.bounds.midX, y: surface.bounds.midY)
        XCTAssertTrue(window.hitTest(surface.convert(center, to: window), with: nil) === surface)
        XCTAssertFalse(window.interactions.contains { $0 is UIDropInteraction })
    }

    @MainActor func testLibraryCardHasAnEnabledNativeDragAndDropSurface() async throws {
        let content = Text("Card").frame(width: 300, height: 100).background(Color.gray)
            .modifier(MasteryReorderModifier(id: UUID(), songs: true, title: "Card", open: {}, move: { _ in }))
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 800, height: 600))
        let host = UIHostingController(rootView: content)
        window.rootViewController = host
        window.makeKeyAndVisible()
        defer { window.isHidden = true; window.rootViewController = nil }
        host.view.layoutIfNeeded()
        try await Task.sleep(nanoseconds: 1_000_000_000)
        let surface = try XCTUnwrap(descendants(host.view).first { view in
            view.accessibilityIdentifier == "mac.library.dragSurface"
        })
        let drag = try XCTUnwrap(surface.interactions.compactMap { $0 as? UIDragInteraction }.first)
        XCTAssertTrue(drag.isEnabled)
        XCTAssertTrue(surface.interactions.contains { $0 is UIDropInteraction })
        let center = CGPoint(x: surface.bounds.midX, y: surface.bounds.midY)
        let hit = window.hitTest(surface.convert(center, to: window), with: nil)
        XCTAssertTrue(hit === surface, "Expected drag surface; got \(String(describing: hit)) at \(surface.convert(center, to: window))")
    }

    @MainActor private func descendants(_ view: UIView) -> [UIView] {
        [view] + view.subviews.flatMap { descendants($0) }
    }
}
#endif
