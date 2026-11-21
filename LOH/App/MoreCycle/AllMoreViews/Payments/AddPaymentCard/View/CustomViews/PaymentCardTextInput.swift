import SwiftUI
import UIKit

/// Keeps the native editing buffer and the form in sync on every keystroke.
struct PaymentCardTextInput: UIViewRepresentable {
    @Binding var text: String
    @Binding var focusedField: AddPaymentCardField?
    let field: AddPaymentCardField
    let placeholder: String
    let title: String
    let numeric: Bool
    let secure: Bool
    @Environment(\.layoutDirection) private var direction
    @Environment(\.isEnabled) private var isEnabled

    func makeUIView(context: Context) -> UITextField {
        let input = UITextField()
        input.delegate = context.coordinator
        input.addTarget(context.coordinator, action: #selector(Coordinator.editingChanged(_:)), for: .editingChanged)
        input.borderStyle = .none
        input.backgroundColor = .clear
        input.font = AppFont.uiFont(.regular, size: 14)
        input.adjustsFontForContentSizeCategory = true
        input.textColor = UIColor(AppColor.text)
        input.tintColor = UIColor(AppColor.primary)
        input.keyboardType = numeric ? .numberPad : .default
        input.autocapitalizationType = numeric ? .none : .words
        input.autocorrectionType = .no
        input.spellCheckingType = .no
        input.isSecureTextEntry = secure
        input.accessibilityLabel = title
        input.accessibilityIdentifier = "payment-card-\(field)"
        input.setContentHuggingPriority(.defaultLow, for: .horizontal)
        input.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        let toolbar = UIToolbar()
        toolbar.items = [
            UIBarButtonItem(systemItem: .flexibleSpace),
            UIBarButtonItem(
                title: "more.Done".localized, style: .done, target: context.coordinator,
                action: #selector(Coordinator.done))
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
        input.semanticContentAttribute = numeric || direction == .leftToRight ? .forceLeftToRight : .forceRightToLeft
        input.textAlignment = numeric || direction == .leftToRight ? .left : .right
        input.attributedPlaceholder = NSAttributedString(
            string: placeholder, attributes: [.foregroundColor: UIColor(AppColor.mutedText)])
        if input.text != text {
            context.coordinator.display(text, in: input)
        }
        if input.isFirstResponder && focusedField != field {
            input.resignFirstResponder()
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
        var parent: PaymentCardTextInput
        weak var input: UITextField?

        init(parent: PaymentCardTextInput) {
            self.parent = parent
        }

        func textFieldDidBeginEditing(_ textField: UITextField) {
            parent.focusedField = parent.field
        }

        func textFieldDidEndEditing(_ textField: UITextField) {
            editingChanged(textField)
            if parent.focusedField == parent.field {
                parent.focusedField = nil
            }
        }

        @objc func editingChanged(_ input: UITextField) {
            guard input.markedTextRange == nil else {
                return
            }
            let value = parent.field.formatted(input.text ?? "")
            // Update the visible text immediately, including during a focused edit.
            if input.text != value {
                display(value, in: input)
            }
            if parent.text != value {
                parent.text = value
            }
        }

        func display(_ value: String, in input: UITextField) {
            let oldText = input.text ?? ""
            let cursor = input.selectedTextRange.map {
                input
                    .offset(from: input.beginningOfDocument, to: $0.start)
            }
            let prefix = (oldText as NSString).substring(to: min(cursor ?? oldText.utf16.count, oldText.utf16.count))
            let digitCount = AccountValidation.digits(prefix).count
            input.text = value
            guard input.isFirstResponder, let cursor else {
                return
            }
            let offset: Int
            if parent.numeric {
                var seen = 0
                offset =
                    value.prefix { character in
                        guard seen < digitCount else {
                            return false
                        }
                        if character.wholeNumberValue != nil {
                            seen += 1
                        }
                        return true
                    }
                    .utf16.count
            } else {
                offset = min(cursor, value.utf16.count)
            }
            if let position =
                input
                .position(from: input.beginningOfDocument, offset: offset)
            {
                input.selectedTextRange = input.textRange(from: position, to: position)
            }
        }

        @objc func done() {
            input?.resignFirstResponder()
        }
    }
}
