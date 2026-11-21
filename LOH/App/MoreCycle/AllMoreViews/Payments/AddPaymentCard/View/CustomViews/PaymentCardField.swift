import SwiftUI

struct PaymentCardField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    let icon: LOHAsset
    var iconSize: CGFloat = 16
    var numeric = false
    var secure = false
    let field: AddPaymentCardField
    @Binding var focus: AddPaymentCardField?
    var error: String? = nil
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(AppFont.bold(size: 13))
            HStack(spacing: 12) {
                profileIcon(icon, size: iconSize)
                PaymentCardTextInput(
                    text: $text, focusedField: $focus, field: field,
                    placeholder: placeholder, title: title, numeric: numeric, secure: secure
                )
                .frame(maxWidth: .infinity, minHeight: 24)
            }
            .padding(.horizontal, 12)
            .frame(minHeight: 43)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(error == nil ? AppColor.border : AppColor.error))
            if let error {
                Text(error)
                    .font(AppFont.regular(size: 11))
                    .foregroundStyle(AppColor.error)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
