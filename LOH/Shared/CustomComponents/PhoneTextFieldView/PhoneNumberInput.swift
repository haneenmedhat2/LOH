import SwiftUI
import UIKit

/// Matches Rahhal's UIKit-backed phone input, with explicit text colors and LTR editing.
struct PhoneNumberInput: UIViewRepresentable {
    @Binding var text: String
    let placeholder: String
    var onFocusChange: (Bool) -> Void = { _ in }

    func makeUIView(context: Context) -> UITextField {
        let field = UITextField()
        field.delegate = context.coordinator
        field.keyboardType = .phonePad
        field.textContentType = .telephoneNumber
        field.textAlignment = .left
        field.semanticContentAttribute = .forceLeftToRight
        field.autocorrectionType = .no
        field.setContentHuggingPriority(.defaultLow, for: .horizontal)
        field.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        field.addTarget(context.coordinator, action: #selector(Coordinator.changed(_:)), for: .editingChanged)
        let toolbar = UIToolbar()
        toolbar.items = [
            UIBarButtonItem(systemItem: .flexibleSpace),
            UIBarButtonItem(
                title: "Done".localized, style: .done, target: context.coordinator, action: #selector(Coordinator.done))
        ]
        toolbar.sizeToFit()
        field.inputAccessoryView = toolbar
        context.coordinator.field = field
        return field
    }

    func updateUIView(_ field: UITextField, context: Context) {
        context.coordinator.parent = self
        let value = AccountValidation.phoneDigits(text)
        if field.text != value {
            field.text = value
        }
        field.font = AppFont.uiFont(.regular, size: 15, relativeTo: .body)
        field.adjustsFontForContentSizeCategory = true
        field.textColor = UIColor(AppColor.text)
        field.tintColor = UIColor(AppColor.primary)
        field.defaultTextAttributes[.foregroundColor] = UIColor(AppColor.text)
        field.attributedPlaceholder = NSAttributedString(
            string: placeholder, attributes: [.foregroundColor: UIColor(AppColor.mutedText)])
        field.accessibilityLabel = "auth.phone".localized
        (field.inputAccessoryView as? UIToolbar)?.items?.last?.title = "Done".localized
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    final class Coordinator: NSObject, UITextFieldDelegate {
        var parent: PhoneNumberInput
        weak var field: UITextField?
        init(_ parent: PhoneNumberInput) {
            self.parent = parent
        }
        @objc func changed(_ field: UITextField) {
            let value = AccountValidation.phoneDigits(field.text ?? "")
            if field.text != value {
                field.text = value
            }
            parent.text = value
        }
        @objc func done() {
            field?.resignFirstResponder()
        }
        func textFieldDidBeginEditing(_ textField: UITextField) {
            parent.onFocusChange(true)
        }
        func textFieldDidEndEditing(_ textField: UITextField) {
            parent.onFocusChange(false)
        }
    }
}
