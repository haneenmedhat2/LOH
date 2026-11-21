import SwiftUI
import UIKit

struct MainAppTextFieldView: View {
    @Binding var text: String
    @Binding var forceValidate: Bool
    let title: String
    let placeHolder: String
    let submitLabel: SubmitLabel
    let keyboardType: UIKeyboardType
    let titleSize: CGFloat
    let height: CGFloat
    let radius: CGFloat
    let isPhone: Bool
    let unitSuffix: String?
    let leadingImage: Image?
    let trailingImage: Image?
    let isSecure: Bool
    let hasError: Bool
    let errorMessage: String
    let contentType: UITextContentType?
    var countryCode: String = "+966"
    @State private var isPasswordVisible = false
    @State private var isFocused = false
    @ScaledMetric(relativeTo: .body) private var minimumFieldHeight = AppMetrics.fieldHeight

    init(
        text: Binding<String>, forceValidate: Binding<Bool> = .constant(true),
        title: String, placeHolder: String, submitLabel: SubmitLabel, keyboardType: UIKeyboardType,
        titleSize: CGFloat = 15, height: CGFloat = AppMetrics.fieldHeight,
        radius: CGFloat = AppRadius.standard, isPhone: Bool = false,
        unitSuffix: String? = nil, leadingImage: Image? = nil, trailingImage: Image? = nil,
        isSecure: Bool = false, hasError: Bool = false, errorMessage: String = "",
        contentType: UITextContentType? = nil
    ) {
        self._text = text
        self._forceValidate = forceValidate
        self.title = title
        self.placeHolder = placeHolder
        self.submitLabel = submitLabel
        self.keyboardType = keyboardType
        self.titleSize = titleSize
        self.height = height
        self.radius = radius
        self.isPhone = isPhone
        self.unitSuffix = unitSuffix
        self.leadingImage = leadingImage
        self.trailingImage = trailingImage
        self.isSecure = isSecure
        self.hasError = hasError
        self.errorMessage = errorMessage
        self.contentType = contentType
    }

    private var borderColor: Color {
        hasError ? AppColor.error : (isFocused ? AppColor.primary : AppColor.border)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            Text(title)
                .font(AppFont.medium(size: titleSize))
                .foregroundStyle(AppColor.text)
            HStack(spacing: AppSpacing.small) {
                if let leadingImage {
                    fieldIcon(leadingImage)
                }
                if isPhone {
                    Text(countryCode)
                        .font(AppFont.regular(size: 15))
                        .environment(\.layoutDirection, .leftToRight)
                }
                CustomTextField(
                    text: $text, placeholder: placeHolder,
                    keyboardType: keyboardType, submitLabel: submitLabel,
                    isSecure: isSecure && !isPasswordVisible,
                    onFocusChange: {
                        isFocused = $0
                    }, contentType: contentType
                )
                .accessibilityLabel(title)
                .frame(maxWidth: .infinity)
                if let unitSuffix {
                    Text(unitSuffix)
                        .font(AppFont.caption)
                        .foregroundStyle(AppColor.secondaryText)
                }
                if isSecure {
                    Button {
                        isPasswordVisible.toggle()
                    } label: {
                        Group {
                            if isPasswordVisible {
                                Image(systemName: "eye")
                            } else {
                                Image("lohEyeOff")
                                    .renderingMode(.template)
                                    .resizable()
                                    .scaledToFit()
                            }
                        }
                        .frame(width: 20, height: 20)
                        .frame(width: AppMetrics.touchTarget, height: AppMetrics.touchTarget)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(AppColor.mutedText)
                    .accessibilityLabel((isPasswordVisible ? "Hide password" : "Show password").localized)
                } else if let trailingImage {
                    fieldIcon(trailingImage)
                }
            }
            .padding(.horizontal, AppSpacing.standard)
            .frame(minHeight: max(height, minimumFieldHeight))
            .background(AppColor.surface, in: RoundedRectangle(cornerRadius: radius))
            .overlay(
                RoundedRectangle(cornerRadius: radius)
                    .strokeBorder(borderColor, lineWidth: 1))
            if hasError && !errorMessage.isEmpty {
                Text(errorMessage)
                    .font(AppFont.caption)
                    .foregroundStyle(AppColor.error)
            }
        }
    }

    private func fieldIcon(_ image: Image) -> some View {
        image
            .resizable()
            .scaledToFit()
            .frame(width: 20, height: 20)
            .foregroundStyle(AppColor.mutedText)
            .accessibilityHidden(true)
    }
}
