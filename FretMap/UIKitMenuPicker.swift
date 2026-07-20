import SwiftUI
import UIKit

struct MenuPickerItem<Value: Hashable>: Identifiable {
    let value: Value
    let title: String

    var id: Value { value }
}

struct UIKitMenuPicker<Value: Hashable>: UIViewRepresentable {
    let title: String
    @Binding var selection: Value
    let options: [MenuPickerItem<Value>]
    var displaysTitle = true

    func makeUIView(context: Context) -> UIButton {
        let button = UIButton(type: .system)
        button.showsMenuAsPrimaryAction = true
        button.changesSelectionAsPrimaryAction = false
        button.contentHorizontalAlignment = .fill
        button.titleLabel?.lineBreakMode = .byTruncatingTail
        button.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        button.setContentHuggingPriority(.defaultLow, for: .horizontal)
        button.layer.cornerRadius = 8
        button.clipsToBounds = true
        return button
    }

    func updateUIView(_ button: UIButton, context: Context) {
        var configuration = UIButton.Configuration.filled()
        configuration.baseBackgroundColor = UIColor(red: 0.24, green: 0.28, blue: 0.38, alpha: 0.9)
        configuration.baseForegroundColor = UIColor.white.withAlphaComponent(0.92)
        configuration.cornerStyle = .medium
        configuration.image = UIImage(systemName: "chevron.up.chevron.down")
        configuration.imagePlacement = .trailing
        configuration.imagePadding = 8
        configuration.titleAlignment = .leading
        configuration.titleLineBreakMode = .byTruncatingTail
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 14, bottom: 0, trailing: 12)
        configuration.attributedTitle = AttributedString(
            displaysTitle ? "\(title): \(selectedTitle)" : selectedTitle
        )

        UIView.performWithoutAnimation {
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            button.configuration = configuration
            button.menu = UIMenu(children: options.map { item in
                UIAction(title: item.title, state: item.value == selection ? .on : .off) { _ in
                    setSelectionWithoutAnimation(item.value)
                }
            })
            button.accessibilityLabel = displaysTitle ? "\(title): \(selectedTitle)" : selectedTitle
            CATransaction.commit()
            button.layoutIfNeeded()
        }
    }

    private var selectedTitle: String {
        options.first { $0.value == selection }?.title ?? options.first?.title ?? ""
    }

    private func setSelectionWithoutAnimation(_ value: Value) {
        UIView.performWithoutAnimation {
            var transaction = Transaction()
            transaction.animation = nil
            transaction.disablesAnimations = true
            withTransaction(transaction) {
                selection = value
            }
        }
    }
}
