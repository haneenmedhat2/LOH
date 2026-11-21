import SwiftUI

struct AccountPasswordView: View {
    @EnvironmentObject private var requests: AccountRequestController
    @StateObject var viewModel: AccountPasswordViewModel
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        Group {
            if viewModel.completed {
                PasswordChangedView(
                    onReturnToLogin: {
                        dismiss()
                    }, fromSettings: true)
            } else {
                AccountPage(
                    title: "more.Change password".localized, hidesTabBar: true, headerHeight: 56, contentTopPadding: 12
                ) {
                    HStack(spacing: 12) {
                        SettingsIcon(name: "PasswordHero", width: 22)
                            .frame(width: 44, height: 44)
                            .background(AppColor.primary, in: RoundedRectangle(cornerRadius: 16))
                        VStack(alignment: .leading, spacing: 4) {
                            Text("settings.Password heading".localized)
                                .font(AppFont.extraBold(size: 15))
                            Text("settings.Password intro".localized)
                                .font(AppFont.regular(size: 10))
                                .foregroundStyle(AppColor.secondaryText)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(12)
                    .background(AppColor.surface, in: RoundedRectangle(cornerRadius: 16))
                    CardContainer(padding: 12) {
                        VStack(spacing: 12) {
                            SettingsPasswordField(
                                title: "settings.Current password".localized,
                                placeholder: "settings.Current placeholder".localized, text: $viewModel.form.current,
                                current: true)
                            SettingsPasswordField(
                                title: "recovery.newPassword".localized,
                                placeholder: "settings.New placeholder".localized, text: $viewModel.form.password)
                            SettingsPasswordField(
                                title: "settings.Confirm new password".localized,
                                placeholder: "settings.Confirm placeholder".localized,
                                text: $viewModel.form.confirmation)
                            if !viewModel.form.confirmation.isEmpty
                                && viewModel.form.password != viewModel.form.confirmation
                            {
                                Text("recovery.passwordError".localized)
                                    .font(AppFont.regular(size: 11))
                                    .foregroundStyle(AppColor.error)
                            }
                            if !viewModel.form.password.isEmpty && viewModel.form.password == viewModel.form.current {
                                Text("settings.Different password".localized)
                                    .font(AppFont.regular(size: 11))
                                    .foregroundStyle(AppColor.error)
                            }
                        }
                    }
                    CardContainer(padding: 12) {
                        HStack(alignment: .top, spacing: 12) {
                            SettingsIcon(name: "PasswordTips", width: 16)
                                .frame(width: 32, height: 32)
                                .background(AppColor.primary, in: RoundedRectangle(cornerRadius: 12))
                            VStack(alignment: .leading, spacing: 12) {
                                Text("settings.Password tips".localized)
                                    .font(AppFont.bold(size: 12))
                                ForEach(
                                    [
                                        "recovery.neverShare", "settings.Avoid personal details",
                                        "recovery.uniquePassword"
                                    ], id: \.self
                                ) { key in
                                    HStack(alignment: .top, spacing: 6) {
                                        Circle()
                                            .fill(AppColor.primary)
                                            .frame(width: 3, height: 3)
                                            .padding(.top, 5)
                                        Text(key.localized)
                                            .font(AppFont.regular(size: 11))
                                            .foregroundStyle(AppColor.secondaryText)
                                            .lineSpacing(4)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    AccountFooter(
                        title: "more.Change password".localized, enabled: viewModel.form.valid && !requests.busy
                    ) {
                        Task {
                            await viewModel.submit()
                        }
                    }
                }
            }
        }
    }
}
