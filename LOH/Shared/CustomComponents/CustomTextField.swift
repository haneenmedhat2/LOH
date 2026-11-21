import SwiftUI
import UIKit

struct CustomTextField: UIViewRepresentable {
    @Binding var text: String
    var placeholder: String
    var keyboardType: UIKeyboardType = .default
    var submitLabel: SubmitLabel = .done
    var isSecure = false
    var onCommit: () -> Void = {}
    var onFocusChange: (Bool) -> Void = { _ in }
    var contentType: UITextContentType? = nil

    private var isRTL: Bool {
        AppLanguageManager.shared.isRTL
    }

    private var appFont: UIFont {
        AppFont.uiFont(.regular, size: 15, relativeTo: .body)
    }

    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField()
        textField.delegate = context.coordinator
        textField.keyboardType = keyboardType
        textField.returnKeyType = .done
        textField.isSecureTextEntry = isSecure
        textField.textContentType = contentType
        textField.autocorrectionType = .no
        textField.autocapitalizationType = .none
        textField.setContentHuggingPriority(.required, for: .horizontal)
        textField.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        textField.addTarget(context.coordinator, action: #selector(Coordinator.changed(_:)), for: .editingChanged)
        update(textField)
        return textField
    }

    func updateUIView(_ uiView: UITextField, context: Context) {
        context.coordinator.parent = self
        update(uiView)
    }

    private func update(_ textField: UITextField) {
        if textField.text != text {
            textField.text = text
        }
        textField.keyboardType = keyboardType
        textField.returnKeyType = .done
        textField.isSecureTextEntry = isSecure
        textField.textContentType = contentType
        textField.font = appFont
        textField.textColor = UIColor(AppColor.text)
        textField.tintColor = UIColor(AppColor.primary)
        textField.textAlignment = isRTL ? .right : .left
        textField.semanticContentAttribute = isRTL ? .forceRightToLeft : .forceLeftToRight
        textField.setContentHuggingPriority(.defaultLow, for: .horizontal)
        textField.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        updatePlaceholder(for: textField)
    }

    private func updatePlaceholder(for textField: UITextField) {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = isRTL ? .right : .left
        paragraphStyle.baseWritingDirection = isRTL ? .rightToLeft : .leftToRight
        textField.attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [
                .foregroundColor: UIColor(AppColor.mutedText),
                .font: appFont,
                .paragraphStyle: paragraphStyle
            ])
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    final class Coordinator: NSObject, UITextFieldDelegate {
        var parent: CustomTextField

        init(_ parent: CustomTextField) {
            self.parent = parent
        }

        @objc func changed(_ textField: UITextField) {
            parent.text = textField.text ?? ""
        }

        func textFieldDidChangeSelection(_ textField: UITextField) {
            parent.text = textField.text ?? ""
        }

        func textFieldDidBeginEditing(_ textField: UITextField) {
            parent.onFocusChange(true)
        }

        func textFieldDidEndEditing(_ textField: UITextField) {
            parent.onFocusChange(false)
        }

        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            parent.onCommit()
            textField.resignFirstResponder()
            return true
        }
    }
}
