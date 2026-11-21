import SwiftUI

struct PasswordRequirementsView: View {
    let hasMinimumLength: Bool
    let hasUppercase: Bool
    let hasNumber: Bool
    @ObservedObject private var language = AppLanguageManager.shared
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        let layout =
            dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 8))
            : AnyLayout(HStackLayout(spacing: 12))
        layout {
            requirement("auth.passwordLength", satisfied: hasMinimumLength)
            requirement("auth.passwordUppercase", satisfied: hasUppercase)
            requirement("auth.passwordNumber", satisfied: hasNumber)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .environment(\.layoutDirection, language.layoutDirection)
    }

    private func requirement(_ key: String, satisfied: Bool) -> some View {
        HStack(spacing: 4) {
            LOHAsset.checkCircle.image
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 14, height: 14)
                .accessibilityHidden(true)
            Text(key.localized)
                .font(AppFont.regular(size: 11))
        }
        .foregroundStyle(satisfied ? AppColor.success : AppColor.mutedText)
        .accessibilityElement(children: .combine)
        .accessibilityValue((satisfied ? "auth.requirementMet" : "auth.requirementNotMet").localized)
    }
}
