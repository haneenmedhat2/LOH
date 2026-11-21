import SwiftUI

/// Shared guest prompt for purchases and all account-only actions.
struct HomeLoginSheet: View {
    @EnvironmentObject private var app: AppCoordinator
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var language = AppLanguageManager.shared
    var offer: HomeOffer? = nil
    var hint = "loginBuyHint"
    var destination: GuestDestination? = nil

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                Image("lohGuestSheetLock")
                    .resizable().scaledToFit().frame(width: 26, height: 26)
                    .frame(width: 56, height: 56)
                    .background(AppColor.errorSurface, in: Circle())
                    .accessibilityHidden(true)
                Text(homeText("loginFirst"))
                    .font(AppFont.black(size: 18))
                    .padding(.top, 16)
                Text(homeText(hint))
                    .font(AppFont.regular(size: 13))
                    .foregroundStyle(AppColor.secondaryText)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(3)
                    .padding(.top, 6)
                    .padding(.bottom, 20)
                MainAppButton(title: homeText("login"), action: { authenticate(register: false) }, height: 52)
                MainAppButton(title: homeText("register"), action: { authenticate(register: true) },
                              variant: .outlined, height: 54)
                    .padding(.top, 10)
            }
            .padding(.horizontal, 20)
            .padding(.top, 30)
            .padding(.bottom, 8)
            .frame(maxWidth: 500)
            .frame(maxWidth: .infinity)
        }
        .scrollIndicators(.hidden)
        .foregroundStyle(AppColor.text)
        .presentationDetents([.height(330), .large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(28)
        .presentationBackground(AppColor.surface)
        .environment(\.layoutDirection, language.layoutDirection)
        .environment(\.locale, Locale(identifier: language.selectedLanguage))
    }

    private func authenticate(register: Bool) {
        dismiss()
        app.beginAuthentication(register: register, destination: offer.map { .home(.offer($0)) } ?? destination)
    }
}
