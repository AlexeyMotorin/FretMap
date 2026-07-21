import SwiftUI
import UIKit

struct MenuPickerItem<Value: Hashable>: Identifiable {
    let value: Value
    let title: String

    var id: Value { value }
}

struct MenuPickerSection<Value: Hashable>: Identifiable {
    let title: String
    let items: [MenuPickerItem<Value>]

    var id: String { title }
}

struct UIKitMenuPicker<Value: Hashable>: UIViewRepresentable {
    let title: String
    @Binding var selection: Value
    let options: [MenuPickerItem<Value>]
    var displaysTitle = true
    var additionalSections: [MenuPickerSection<Value>] = []

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
        let localizedTitle = L10n.string(title)
        let localizedSelection = L10n.string(selectedTitle)
        configuration.attributedTitle = AttributedString(
            displaysTitle ? "\(localizedTitle): \(localizedSelection)" : localizedSelection
        )

        UIView.performWithoutAnimation {
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            button.configuration = configuration
            let primaryActions = options.map { item in
                UIAction(title: L10n.string(item.title), state: item.value == selection ? .on : .off) { _ in
                    setSelectionWithoutAnimation(item.value)
                }
            }
            let nestedMenus = additionalSections.map { section in
                UIMenu(
                    title: L10n.string(section.title),
                    children: section.items.map { item in
                        UIAction(title: L10n.string(item.title), state: item.value == selection ? .on : .off) { _ in
                            setSelectionWithoutAnimation(item.value)
                        }
                    }
                )
            }
            button.menu = UIMenu(children: primaryActions + nestedMenus)
            button.accessibilityLabel = displaysTitle
                ? "\(localizedTitle): \(localizedSelection)"
                : localizedSelection
            CATransaction.commit()
            button.layoutIfNeeded()
        }
    }

    private var selectedTitle: String {
        let allOptions = options + additionalSections.flatMap(\.items)
        return allOptions.first { $0.value == selection }?.title ?? allOptions.first?.title ?? ""
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
