import SwiftUI

struct VerificationCodeDigitView: View {
    @Binding var text: String
    var isFocused: Bool
    var hasError = false
    var size: CGFloat = 68

    var body: some View {
        TextField("", text: $text)
            .font(AppFont.bold(size: 28))
            .foregroundStyle(AppColor.text)
            .multilineTextAlignment(.center)
            .keyboardType(.numberPad)
            .tint(AppColor.primary)
            .frame(width: size, height: size)
            .background(AppColor.surface, in: RoundedRectangle(cornerRadius: AppRadius.standard))
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.standard)
                    .strokeBorder(
                        hasError ? AppColor.error : (isFocused ? AppColor.primary : AppColor.border), lineWidth: 1)
            )
            .environment(\.layoutDirection, .leftToRight)
            .onChange(of: text) { value in
                let digit = String(value.filter(\.isNumber).prefix(1))
                if digit != text {
                    text = digit
                }
            }
    }
}
