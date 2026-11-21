import SwiftUI

struct PasswordChangedView: View {
    let onReturnToLogin: () -> Void
    var fromSettings = false
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 16) {
                    Image("lohPasswordChanged")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 88)
                        .frame(width: 128, height: 112)
                        .overlay(alignment: .bottomTrailing) {
                            Image("lohPasswordChangedCheck")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 18, height: 18)
                                .frame(width: 40, height: 40)
                                .background(AppColor.success, in: Circle())
                                .overlay(
                                    Circle()
                                        .stroke(AppColor.accountCanvas, lineWidth: 4)
                                )
                                .padding(.trailing, 12)
                        }
                        .environment(\.layoutDirection, .leftToRight)
                        .padding(.vertical, 8)
                        .accessibilityHidden(true)
                    VStack(spacing: 10) {
                        Text("recovery.changedTitle".localized)
                            .font(AppFont.black(size: 18))
                        Text("recovery.changedMessage".localized)
                            .font(AppFont.regular(size: 12))
                            .foregroundStyle(AppColor.secondaryText)
                    }
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 8) {
                            Image("lohPasswordProtection")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 14, height: 14)
                                .frame(width: 28, height: 28)
                                .background(AppColor.primary, in: RoundedRectangle(cornerRadius: 12))
                                .accessibilityHidden(true)
                            Text("recovery.protectAccount".localized)
                                .font(AppFont.bold(size: 13))
                        }
                        VStack(spacing: 0) {
                            tip("recovery.neverShare")
                            Divider()
                            tip("recovery.uniquePassword")
                            Divider()
                            tip("recovery.unusualActivity")
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(AppColor.surface, in: RoundedRectangle(cornerRadius: 16))
                    MainAppButton(
                        title: (fromSettings ? "more.Back to settings" : "recovery.backLogin").localized,
                        action: onReturnToLogin, variant: .action, height: 51)

                }
                .padding(.horizontal, 16)
                .padding(.vertical, 24)
                .frame(minHeight: geometry.size.height)
            }
        }
        .background(
            AppColor.accountCanvas
                .ignoresSafeArea()
        )
        .foregroundStyle(AppColor.text)
        .modifier(AppNavigationBarModifier(title: "more.Change password".localized))
        .navigationBarBackButtonHidden()
        .toolbar(.visible, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .toolbarBackground(AppColor.accountCanvas, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }
    private func tip(_ key: String) -> some View {
        HStack(spacing: 12) {
            Image("lohPasswordTipCheck")
                .resizable()
                .scaledToFit()
                .frame(width: 10, height: 10)
                .frame(width: 20, height: 20)
                .background(AppColor.success, in: Circle())
                .accessibilityHidden(true)
            Text(key.localized)
                .font(AppFont.regular(size: 12))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 10)
    }
}
