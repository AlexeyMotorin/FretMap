#if targetEnvironment(macCatalyst)
import SwiftUI

extension View {
    /// Mac editors stay in their hosting window. Closing the binding removes the
    /// dialog directly, without a Catalyst sheet presentation/dismissal cycle.
    func macEditorDialog<Dialog: View>(isPresented: Binding<Bool>, width: CGFloat = 620,
                                       height: CGFloat = 640, @ViewBuilder content: () -> Dialog) -> some View {
        disabled(isPresented.wrappedValue)
            .overlay {
                if isPresented.wrappedValue {
                    ZStack {
                        Color.black.opacity(0.45).ignoresSafeArea()
                        content()
                            .frame(maxWidth: width, maxHeight: height)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(AppColors.border))
                            .shadow(color: .black.opacity(0.4), radius: 24)
                            .padding(24)
                            .environment(\.isEnabled, true)
                            .accessibilityAddTraits(.isModal)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
    }

    func macEditorDialog<Item: Identifiable, Dialog: View>(item: Binding<Item?>, width: CGFloat = 620,
                                                          height: CGFloat = 640,
                                                          @ViewBuilder content: (Item) -> Dialog) -> some View {
        macEditorDialog(isPresented: Binding(get: { item.wrappedValue != nil }, set: { if !$0 { item.wrappedValue = nil } }),
                        width: width, height: height) {
            if let value = item.wrappedValue { content(value) }
        }
    }
}
#endif
