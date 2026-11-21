import SwiftUI
import UIKit

/// Native decimal input with explicit text attributes so entered values remain visible.
struct HomePriceTextInput: UIViewRepresentable {
    @Binding var text: String
    let placeholder: String
    @Environment(\.isEnabled) private var isEnabled

    func makeUIView(context: Context) -> UITextField {
        let field = UITextField()
        field.keyboardType = .decimalPad
        field.textAlignment = .left
        field.semanticContentAttribute = .forceLeftToRight
        field.autocorrectionType = .no
        field.borderStyle = .none
        field.setContentHuggingPriority(.defaultLow, for: .horizontal)
        field.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        field.addTarget(context.coordinator, action: #selector(Coordinator.changed(_:)), for: .editingChanged)
        field.delegate = context.coordinator
        let toolbar = UIToolbar()
        toolbar.items = [
            UIBarButtonItem(systemItem: .flexibleSpace),
            UIBarButtonItem(title: "Done".localized, style: .done,
                            target: context.coordinator, action: #selector(Coordinator.done))
        ]
        toolbar.sizeToFit()
        field.inputAccessoryView = toolbar
        context.coordinator.field = field
        return field
    }

    func updateUIView(_ field: UITextField, context: Context) {
        context.coordinator.parent = self
        field.isEnabled = isEnabled
        let font = AppFont.uiFont(.regular, size: 13)
        let color = UIColor(AppColor.text)
        field.defaultTextAttributes = [.font: font, .foregroundColor: color]
        field.font = font
        field.textColor = color
        field.tintColor = UIColor(AppColor.primary)
        field.attributedPlaceholder = NSAttributedString(
            string: placeholder, attributes: [.font: font, .foregroundColor: UIColor(AppColor.mutedText)])
        field.accessibilityLabel = placeholder
        (field.inputAccessoryView as? UIToolbar)?.items?.last?.title = "Done".localized
        if field.text != text && field.markedTextRange == nil { field.text = text }
    }

    func sizeThatFits(_ proposal: ProposedViewSize, uiView: UITextField, context: Context) -> CGSize? {
        CGSize(width: proposal.width ?? uiView.intrinsicContentSize.width,
               height: max(24, uiView.intrinsicContentSize.height))
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }
    final class Coordinator: NSObject, UITextFieldDelegate {
        var parent: HomePriceTextInput
        weak var field: UITextField?
        init(_ parent: HomePriceTextInput) { self.parent = parent }
        @objc func changed(_ field: UITextField) {
            guard field.markedTextRange == nil else { return }
            parent.text = field.text ?? ""
        }
        func textFieldDidEndEditing(_ textField: UITextField) { changed(textField) }
        @objc func done() { field?.resignFirstResponder() }
    }
}
