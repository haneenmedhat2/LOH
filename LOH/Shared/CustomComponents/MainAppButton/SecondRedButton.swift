import SwiftUI

struct SecondRedButton: View {
    let title: String
    let action: VoidCompletion
    var height: CGFloat = AppMetrics.buttonHeight
    var cornerRadius: CGFloat = AppRadius.standard
    var horizontalPadding: CGFloat = 0
    var font: Font = AppFont.button

    var body: some View {
        Button(action: action) {
            Text(title)
                .multilineTextAlignment(.center)
        }
        .buttonStyle(
            SecondRedButtonStyle(
                height: height, cornerRadius: cornerRadius,
                horizontalPadding: horizontalPadding, font: font))
    }
}
struct SecondRedButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    var foregroundColor: Color = AppColor.error
    var backgroundColor: Color = AppColor.errorSurface
    var height: CGFloat = AppMetrics.buttonHeight
    var cornerRadius: CGFloat = AppRadius.standard
    var horizontalPadding: CGFloat = 0
    var font: Font = AppFont.button

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(font)
            .padding(.horizontal, AppSpacing.standard)
            .padding(.vertical, AppSpacing.medium)
            .frame(maxWidth: .infinity, minHeight: height)
            .foregroundStyle(isEnabled ? foregroundColor : AppColor.mutedText)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(isEnabled ? backgroundColor : AppColor.disabledSurface)
            )
            .padding(.horizontal, horizontalPadding)
            .opacity(configuration.isPressed ? 0.85 : 1)
    }
}
