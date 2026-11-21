import SwiftUI
import UIKit

/// Synchronizes the native editing buffer and SwiftUI binding before focus changes.
struct AccountPhoneTextInput: UIViewRepresentable {
    @Binding var text: String
    let placeholder: String
    let title: String
    @Environment(\.isEnabled) private var isEnabled

    func makeUIView(context: Context) -> UITextField {
        let input = UITextField()
        input.delegate = context.coordinator
        input.addTarget(context.coordinator, action: #selector(Coordinator.editingChanged(_:)), for: .editingChanged)
        input.font = AppFont.uiFont(.regular, size: 13)
        input.textColor = UIColor(AppColor.text)
        input.tintColor = UIColor(AppColor.primary)
        input.keyboardType = .phonePad
        input.textContentType = .telephoneNumber
        input.semanticContentAttribute = .forceLeftToRight
        input.textAlignment = .left
        input.borderStyle = .none
        input.autocorrectionType = .no
        input.setContentHuggingPriority(.defaultLow, for: .horizontal)
        input.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        input.accessibilityIdentifier = "account-phone"
        let toolbar = UIToolbar()
        toolbar.items = [
            UIBarButtonItem(systemItem: .flexibleSpace),
            UIBarButtonItem(
                title: "more.Done".localized, style: .done,
                target: context.coordinator, action: #selector(Coordinator.done))
        ]
        toolbar.tintColor = UIColor(AppColor.primary)
        toolbar.sizeToFit()
        input.inputAccessoryView = toolbar
        context.coordinator.input = input
        return input
    }

    func updateUIView(_ input: UITextField, context: Context) {
        context.coordinator.parent = self
        input.isEnabled = isEnabled
        input.accessibilityLabel = title
        input.attributedPlaceholder = NSAttributedString(
            string: placeholder, attributes: [.foregroundColor: UIColor(AppColor.mutedText)])
        let value = AccountValidation.phoneDigits(text)
        if input.text != value && input.markedTextRange == nil {
            context.coordinator.display(value, in: input)
        }
    }

    func sizeThatFits(_ proposal: ProposedViewSize, uiView: UITextField, context: Context) -> CGSize? {
        CGSize(
            width: proposal.width ?? uiView.intrinsicContentSize.width,
            height: max(24, uiView.intrinsicContentSize.height))
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    final class Coordinator: NSObject, UITextFieldDelegate {
        var parent: AccountPhoneTextInput
        weak var input: UITextField?
        init(parent: AccountPhoneTextInput) {
            self.parent = parent
        }

        @objc func editingChanged(_ input: UITextField) {
            guard input.markedTextRange == nil else {
                return
            }
            let value = AccountValidation.phoneDigits(input.text ?? "")
            if input.text != value {
                display(value, in: input)
            }
            if parent.text != value {
                parent.text = value
            }
        }
        func textFieldDidEndEditing(_ textField: UITextField) {
            editingChanged(textField)
        }
        @objc func done() {
            input?.resignFirstResponder()
        }

        func display(_ value: String, in input: UITextField) {
            let old = input.text ?? ""
            let cursor = input.selectedTextRange.map {
                input
                    .offset(from: input.beginningOfDocument, to: $0.start)
            }
            let prefix = (old as NSString).substring(to: min(cursor ?? old.utf16.count, old.utf16.count))
            let offset = min(AccountValidation.phoneDigits(prefix).utf16.count, value.utf16.count)
            input.text = value
            if input.isFirstResponder,
                let position =
                    input
                    .position(from: input.beginningOfDocument, offset: offset)
            {
                input.selectedTextRange = input.textRange(from: position, to: position)
            }
        }
    }
}
