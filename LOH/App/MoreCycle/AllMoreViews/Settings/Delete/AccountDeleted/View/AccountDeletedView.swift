import SwiftUI

struct AccountDeletedView: View {
    let onReturnToLogin: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            VStack(spacing: 24) {
                Text("more.Delete account".localized)
                    .font(AppFont.navigationTitle)
                deletionSteps
            }
            .padding(.top, 16)
            .padding(.horizontal, 24)
            ScrollView {
                VStack(spacing: 20) {
                    SettingsIcon(name: "DeletionComplete", width: 176, height: 144)
                        .padding(.vertical, 4)
                    VStack(spacing: 6) {
                        Text("deletion.Completed".localized)
                            .font(AppFont.black(size: 18))
                        Text("deletion.Completed message".localized)
                            .font(AppFont.regular(size: 12))
                            .foregroundStyle(AppColor.secondaryText)
                            .lineSpacing(4)
                    }
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    CardContainer {
                        VStack(spacing: 16) {
                            HStack {
                                Text("deletion.Request completed".localized)
                                    .font(AppFont.extraBold(size: 15))
                                Spacer()
                                SettingsIcon(name: "DeletionDone", width: 18)
                                    .frame(width: 36, height: 36)
                                    .background(AppColor.success, in: RoundedRectangle(cornerRadius: 12))
                            }
                            VStack(spacing: 0) {
                                completedRow("deletion.Profile removed")
                                completedRow("deletion.All devices signed out")
                            }
                        }
                    }
                    HStack(spacing: 16) {
                        SettingsIcon(name: "DeletionWelcome", width: 22)
                            .frame(width: 48, height: 48)
                            .background(Color(red: 1, green: 203 / 255, blue: 184 / 255), in: Circle())
                        VStack(alignment: .leading, spacing: 4) {
                            Text("deletion.Always welcome".localized)
                                .font(AppFont.extraBold(size: 15))
                            Text("deletion.Return anytime".localized)
                                .font(AppFont.regular(size: 13))
                                .foregroundStyle(AppColor.secondaryText)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(16)
                    .background(
                        LinearGradient(
                            colors: [
                                Color(red: 1, green: 245 / 255, blue: 243 / 255),
                                Color(red: 1, green: 234 / 255, blue: 230 / 255)
                            ], startPoint: .topLeading, endPoint: .bottomTrailing),
                        in: RoundedRectangle(cornerRadius: 16))
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
                .frame(maxWidth: 440)
                .frame(maxWidth: .infinity)
            }
        }
        .foregroundStyle(AppColor.text)
        .background(
            AppColor.canvas
                .ignoresSafeArea()
        )
        .safeAreaInset(edge: .bottom, spacing: 0) {
            MainAppButton(title: "more.Back to login".localized, action: onReturnToLogin, variant: .action, height: 56)
                .padding(16)
                .background(AppColor.surface)
        }
        .navigationBarBackButtonHidden()
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
    }
    private var deletionSteps: some View {
        HStack(alignment: .top, spacing: 4) {
            step("deletion.Request")
            Rectangle()
                .fill(AppColor.primary)
                .frame(width: 64, height: 2)
                .padding(.top, 17)
            step("deletion.Verification")
            Rectangle()
                .fill(AppColor.primary)
                .frame(width: 64, height: 2)
                .padding(.top, 17)
            step("deletion.Deletion")
        }
        .environment(\.layoutDirection, .leftToRight)
    }
    private func step(_ title: String) -> some View {
        VStack(spacing: 4) {
            SettingsIcon(name: "DeletionStep", width: 16)
                .frame(width: 32, height: 32)
                .background(AppColor.primary, in: Circle())
            Text(title.localized)
                .font(AppFont.medium(size: 11))
                .foregroundStyle(AppColor.primary)
        }
    }
    private func completedRow(_ title: String) -> some View {
        HStack(spacing: 12) {
            SettingsIcon(name: "DeletionCheck", width: 12)
                .frame(width: 24, height: 24)
                .background(AppColor.success, in: Circle())
            Text(title.localized)
                .font(AppFont.regular(size: 14))
                .foregroundStyle(AppColor.secondaryText)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 10)
        .overlay(
            Rectangle()
                .strokeBorder(Color(.systemGray6)))
    }
}
