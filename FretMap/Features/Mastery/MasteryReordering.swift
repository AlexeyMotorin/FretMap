import SwiftUI
#if targetEnvironment(macCatalyst)
import UIKit
#endif

struct MasteryReorderModifier: ViewModifier {
    let id: UUID
    let songs: Bool
    let title: String
    let open: () -> Void
    let move: (UUID) -> Void
    @State private var targeted = false
    func body(content: Content) -> some View {
        #if targetEnvironment(macCatalyst)
        content
            .overlay(MacLibraryDragSurface(id: id, songs: songs, title: title, targeted: $targeted, open: open, move: move))
            .contentShape(Rectangle())
            .onTapGesture { open() }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(title))
            .accessibilityAddTraits(.isButton)
            .accessibilityAction { open() }
        #else
        content
        #endif
    }
}

#if targetEnvironment(macCatalyst)
/// A real hit-tested UIKit surface: SwiftUI NavigationLink gestures can consume
/// the mouse movement before onDrag starts in Catalyst.
private struct MacLibraryDragSurface: UIViewRepresentable {
    let id: UUID
    let songs: Bool
    let title: String
    @Binding var targeted: Bool
    let open: () -> Void
    let move: (UUID) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(self) }
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.accessibilityIdentifier = "mac.library.dragSurface"
        view.backgroundColor = .clear
        let drag = UIDragInteraction(delegate: context.coordinator)
        drag.isEnabled = true
        view.addInteraction(drag)
        view.addInteraction(UIDropInteraction(delegate: context.coordinator))
        return view
    }
    func updateUIView(_ view: UIView, context: Context) {
        context.coordinator.owner = self
        view.layer.cornerRadius = 12
        view.layer.borderWidth = targeted ? 2 : 0
        view.layer.borderColor = UIColor.systemBlue.cgColor
    }

    final class Coordinator: NSObject, UIDragInteractionDelegate, UIDropInteractionDelegate {
        var owner: MacLibraryDragSurface
        init(_ owner: MacLibraryDragSurface) { self.owner = owner }
        func dragInteraction(_ interaction: UIDragInteraction, sessionIsRestrictedToDraggingApplication session: UIDragSession) -> Bool { true }
        func dragInteraction(_ interaction: UIDragInteraction, itemsForBeginning session: UIDragSession) -> [UIDragItem] {
            let item = UIDragItem(itemProvider: NSItemProvider(object: owner.title as NSString))
            item.localObject = LibraryDragIdentity(id: owner.id, songs: owner.songs)
            let title = owner.title
            item.previewProvider = {
                let label = UILabel(frame: CGRect(x: 0, y: 0, width: 240, height: 54))
                label.text = "  " + title
                label.backgroundColor = .secondarySystemBackground
                label.textColor = .label
                label.layer.cornerRadius = 10
                label.clipsToBounds = true
                return UIDragPreview(view: label)
            }
            return [item]
        }
        private func identity(_ session: UIDropSession) -> LibraryDragIdentity? {
            guard session.localDragSession != nil,
                  let identity = session.items.first?.localObject as? LibraryDragIdentity,
                  identity.songs == owner.songs, identity.id != owner.id else { return nil }
            return identity
        }
        func dropInteraction(_ interaction: UIDropInteraction, canHandle session: UIDropSession) -> Bool { identity(session) != nil }
        func dropInteraction(_ interaction: UIDropInteraction, sessionDidUpdate session: UIDropSession) -> UIDropProposal {
            let accepts = identity(session) != nil
            owner.targeted = accepts
            return UIDropProposal(operation: accepts ? .move : .cancel)
        }
        func dropInteraction(_ interaction: UIDropInteraction, sessionDidExit session: UIDropSession) { owner.targeted = false }
        func dropInteraction(_ interaction: UIDropInteraction, sessionDidEnd session: UIDropSession) { owner.targeted = false }
        func dropInteraction(_ interaction: UIDropInteraction, performDrop session: UIDropSession) {
            owner.targeted = false
            if let identity = identity(session) { owner.move(identity.id) }
        }
    }
}

private struct LibraryDragIdentity {
    let id: UUID
    let songs: Bool
}
#endif
