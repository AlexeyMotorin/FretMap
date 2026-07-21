import SwiftUI
import UIKit

struct KeyboardDismissTapObserver: UIViewRepresentable {
    let onTapOutsideTextInput: () -> Void

    func makeUIView(context: Context) -> KeyboardDismissTapView {
        let view = KeyboardDismissTapView()
        view.onTapOutsideTextInput = onTapOutsideTextInput
        return view
    }

    func updateUIView(_ view: KeyboardDismissTapView, context: Context) {
        view.onTapOutsideTextInput = onTapOutsideTextInput
    }
}

final class KeyboardDismissTapView: UIView, UIGestureRecognizerDelegate {
    var onTapOutsideTextInput: () -> Void = {}

    private weak var installedWindow: UIWindow?
    private weak var tapRecognizer: UITapGestureRecognizer?

    override func didMoveToWindow() {
        super.didMoveToWindow()
        installRecognizer(on: window)
    }

    deinit {
        if let tapRecognizer {
            installedWindow?.removeGestureRecognizer(tapRecognizer)
        }
    }

    private func installRecognizer(on newWindow: UIWindow?) {
        guard installedWindow !== newWindow else { return }

        if let tapRecognizer {
            installedWindow?.removeGestureRecognizer(tapRecognizer)
        }

        installedWindow = newWindow
        guard let newWindow else {
            tapRecognizer = nil
            return
        }

        let recognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        recognizer.cancelsTouchesInView = false
        recognizer.delegate = self
        newWindow.addGestureRecognizer(recognizer)
        tapRecognizer = recognizer
    }

    @objc private func handleTap() {
        onTapOutsideTextInput()
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        var view = touch.view
        while let currentView = view {
            if currentView is UITextField || currentView is UITextView {
                return false
            }
            view = currentView.superview
        }
        return true
    }
}
