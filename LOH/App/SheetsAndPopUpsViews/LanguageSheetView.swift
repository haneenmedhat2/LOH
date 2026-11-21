import SwiftUI

struct LanguageSheetView: View {
    let onClose: () -> Void

    @ObservedObject private var languageManager = AppLanguageManager.shared
    @State private var pendingLanguage: appLanguage

    init(onClose: @escaping () -> Void) {
        self.onClose = onClose
        let current = appLanguage(rawValue: AppLanguageManager.shared.selectedLanguage) ?? .arabic
        _pendingLanguage = State(initialValue: current)
    }

    var body: some View {
        VStack(spacing: 20) {
            header

            VStack(spacing: 10) {
                languageRow(title: "العربية", language: .arabic, symbol: "character")
                languageRow(title: "English", language: .english, symbol: "a.circle")
            }

            MainAppButton(title: "change_title".localized, action: applyChangeIfNeeded, height: 50)
        }
        .padding(.horizontal, 24)
        .padding(.top, 28)
        .padding(.bottom, 24)
        .frame(maxWidth: .infinity)
        .background(AppColor.canvas.ignoresSafeArea())
        .presentationBackground(AppColor.canvas)
    }

    private var header: some View {
        HStack(spacing: 14) {
            Image(systemName: "globe")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(AppColor.primary)
                .frame(width: 48, height: 48)
                .background(AppColor.primary.opacity(0.1), in: Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text("change_language_title".localized)
                    .font(AppFont.bold(size: 18))
                    .foregroundStyle(AppColor.text)
                Text("change_language_subtitle".localized)
                    .font(AppFont.regular(size: 13))
                    .foregroundStyle(AppColor.secondaryText)
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    private func languageRow(title: String, language: appLanguage, symbol: String) -> some View {
        let isSelected = pendingLanguage == language

        return Button {
            withAnimation(.easeInOut(duration: 0.16)) {
                pendingLanguage = language
            }
        } label: {
            HStack(spacing: 14) {
                Image(systemName: symbol)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(isSelected ? AppColor.primary : AppColor.secondaryText)
                    .frame(width: 38, height: 38)
                    .background(isSelected ? AppColor.primary.opacity(0.1) : AppColor.canvas,
                                in: RoundedRectangle(cornerRadius: 11))

                Text(title)
                    .font(AppFont.medium(size: 16))
                    .foregroundStyle(AppColor.text)

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 21, weight: .medium))
                    .foregroundStyle(isSelected ? AppColor.primary : AppColor.border)
            }
            .padding(.horizontal, 15)
            .frame(height: 64)
            .background(isSelected ? AppColor.primary.opacity(0.06) : AppColor.surface,
                        in: RoundedRectangle(cornerRadius: 16))
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(isSelected ? AppColor.primary : AppColor.border.opacity(0.65), lineWidth: 1)
            }
            .contentShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func applyChangeIfNeeded() {
        let current = appLanguage(rawValue: languageManager.selectedLanguage) ?? .arabic
        if current != pendingLanguage {
            languageManager.setLanguage(pendingLanguage.rawValue)
        }
        onClose()
    }
}
