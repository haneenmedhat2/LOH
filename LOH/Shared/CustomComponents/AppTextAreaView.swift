import SwiftUI

struct AppTextAreaView: View {
    @Binding var text: String
    let title: String
    let placeholder: String
    var minHeight: CGFloat = 120
    var hasError = false
    var errorMessage = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            Text(title)
                .font(AppFont.fieldLabel)
                .foregroundStyle(AppColor.text)
            ZStack(alignment: .topLeading) {
                TextEditor(text: $text)
                    .font(AppFont.regular(size: 15))
                    .foregroundStyle(AppColor.text)
                    .tint(AppColor.primary)
                    .focused($isFocused)
                    .scrollContentBackground(.hidden)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .frame(minHeight: minHeight)
                    .accessibilityLabel(title)
                if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text(placeholder)
                        .font(AppFont.regular(size: 15))
                        .foregroundStyle(AppColor.mutedText)
                        .padding(.horizontal, 17)
                        .padding(.vertical, 16)
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)
                }
            }
            .background(AppColor.surface, in: RoundedRectangle(cornerRadius: AppRadius.standard))
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.standard)
                    .strokeBorder(
                        hasError ? AppColor.error : (isFocused ? AppColor.primary : AppColor.border), lineWidth: 1))
            if hasError && !errorMessage.isEmpty {
                Text(errorMessage)
                    .font(AppFont.caption)
                    .foregroundStyle(AppColor.error)
            }
        }
    }
}
