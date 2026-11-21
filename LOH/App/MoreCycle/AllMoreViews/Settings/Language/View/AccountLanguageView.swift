import SwiftUI

struct AccountLanguageView: View {
    @ObservedObject private var language = AppLanguageManager.shared
    @EnvironmentObject private var account: AccountLanguageViewModel
    @EnvironmentObject private var requests: AccountRequestController
    @State private var selection = ""
    var body: some View {
        AccountPage(title: "more.Language".localized, hidesTabBar: true, headerHeight: 60, contentSpacing: 16) {
            CardContainer {
                HStack(spacing: 16) {
                    SettingsLanguageIllustration()
                    VStack(alignment: .leading, spacing: 4) {
                        Text("more.Choose your preferred language".localized)
                            .font(AppFont.extraBold(size: 18))
                        Text("more.Choose the language you prefer. You can change it at any time.".localized)
                            .font(AppFont.regular(size: 13))
                            .foregroundStyle(AppColor.secondaryText)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            Text("more.Available languages".localized)
                .font(AppFont.bold(size: 16))
            VStack(spacing: 8) {
                ForEach(account.options) { option in
                    languageRow(option.title, code: option.id, flag: option.flag)
                }
            }
            CardContainer {
                HStack(alignment: .top, spacing: 12) {
                    SettingsIcon(name: "LanguageNote", width: 18)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("more.Note".localized)
                            .font(AppFont.bold(size: 14))
                        Text("more.The language will be applied throughout the app when saved.".localized)
                            .font(AppFont.regular(size: 13))
                            .foregroundStyle(AppColor.secondaryText)
                            .lineSpacing(3)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .accessibilityHidden(account.languageChangeConfirmed)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            AccountFooter(
                title: "more.Save".localized,
                enabled: !selection.isEmpty && !account.languageChangeConfirmed && !requests.busy
            ) {
                let selectedLanguage = selection
                Task {
                    if await account.changeLanguage(selectedLanguage) {
                        account.languageChangeConfirmed = true
                        language.setLanguage(selectedLanguage)
                    }
                }
            }
        }
        .overlay {
            if account.languageChangeConfirmed {
                ZStack {
                    Color.black.opacity(0.45)
                        .ignoresSafeArea()
                    VStack(spacing: 20) {
                        SettingsIcon(name: "LanguageSuccess", width: 32)
                            .frame(width: 80, height: 80)
                            .background(AppColor.success, in: Circle())
                        Text("more.Language updated".localized)
                            .font(AppFont.bold(size: 22))
                            .multilineTextAlignment(.center)
                        MainAppButton(
                            title: "settings.Great".localized,
                            action: {
                                account.languageChangeConfirmed = false
                            }, variant: .action, height: 56)
                    }
                    .padding(32)
                    .frame(maxWidth: 320)
                    .background(AppColor.surface, in: RoundedRectangle(cornerRadius: 24))
                    .padding(20)
                    .accessibilityAddTraits(.isModal)
                }
            }
        }
        .onAppear {
            selection = language.selectedLanguage
        }
    }
    private func languageRow(_ title: String, code: String, flag: String) -> some View {
        let selected = selection == code
        return Button {
            selection = code
        } label: {
            HStack(spacing: 12) {
                Text(flag)
                    .font(.system(size: 18))
                    .frame(width: 40, height: 40)
                    .background(
                        code == "ar"
                            ? Color(red: 0, green: 108 / 255, blue: 53 / 255)
                            : Color(red: 178 / 255, green: 34 / 255, blue: 52 / 255), in: Circle()
                    )
                    .overlay(
                        Circle()
                            .strokeBorder(Color(.systemGray6), lineWidth: 2))
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(AppFont.bold(size: 16))
                        .foregroundStyle(AppColor.text)
                    Text(
                        (selected ? "settings.Current language" : code == "en" ? "settings.English" : "settings.Arabic")
                        .localized
                    )
                    .font(AppFont.regular(size: 12))
                    .foregroundStyle(selected ? AppColor.primary : AppColor.secondaryText)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Circle()
                    .strokeBorder(selected ? AppColor.primary : AppColor.mutedText, lineWidth: 2)
                    .frame(width: 20, height: 20)
                    .overlay {
                        if selected {
                            Circle()
                                .fill(AppColor.primary)
                                .frame(width: 10, height: 10)
                        }
                    }
            }
            .padding(16)
            .frame(minHeight: 78)
            .background(AppColor.surface, in: RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(selected ? AppColor.primary : AppColor.border, lineWidth: 2))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}
