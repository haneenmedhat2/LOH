import SwiftUI

struct AccountLogoutSheet: View {
    let onConfirm: () -> Void
    let onCancel: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                Capsule()
                    .fill(AppColor.border)
                    .frame(width: 40, height: 6)
                    .padding(.bottom, 20)
                    .accessibilityHidden(true)
                SettingsIcon(name: "LogoutHero", width: 56)
                    .frame(width: 96, height: 96)
                    .background(AppColor.accentSurface, in: Circle())
                    .padding(.bottom, 16)
                Text("more.Log out?".localized)
                    .font(AppFont.extraBold(size: 20))
                    .padding(.bottom, 8)
                Text("deletion.Logout question".localized)
                    .font(AppFont.regular(size: 14))
                    .foregroundStyle(AppColor.secondaryText)
                    .padding(.bottom, 20)
                MainAppButton(title: "more.Log out".localized, action: onConfirm, height: 56)
                    .padding(.bottom, 12)
                MainAppButton(title: "more.Cancel".localized, action: onCancel, variant: .outlined, height: 58)
                HStack(spacing: 8) {
                    SettingsIcon(name: "LogoutSafety", width: 14)
                    Text("deletion.Logout reassurance".localized)
                        .font(AppFont.regular(size: 12))
                        .foregroundStyle(AppColor.mutedText)
                }
                .padding(.top, 16)
            }
            .multilineTextAlignment(.center)
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 8)
        }
        .scrollIndicators(.hidden)
        .foregroundStyle(AppColor.text)
        .background(AppColor.surface)
        .presentationDetents([.height(389)])
        .presentationDragIndicator(.hidden)
        .presentationBackground(AppColor.surface)
        .presentationCornerRadius(28)
    }
}
