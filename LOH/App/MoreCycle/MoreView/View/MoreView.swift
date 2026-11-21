import SwiftUI

struct MoreScreen: View {
    @EnvironmentObject private var appCoordinator: AppCoordinator
    @EnvironmentObject private var moreCoordinator: MoreCoordinator
    @EnvironmentObject private var account: AccountProfileViewModel
    @EnvironmentObject private var viewModel: MoreViewModel
    @State private var logout = false
    @State private var signingOut = false
    @State private var logoutError: String?

    var body: some View {
        Group {
            if UserDefaults.accessToken == nil { GuestAccountView() }
            else { signedInContent }
        }
    }
    private var signedInContent: some View {
        AccountPage(
            title: "more.My account".localized, back: false, hidesTabBar: !moreCoordinator.path.isEmpty,
            headerHeight: 50,
            onRefresh: {
                guard appCoordinator.isLoggedIn else { return }
                await refreshAccount()
            }
        ) {
            Button {
                moreCoordinator.show(.editProfile)
            } label: {
                CardContainer {
                    HStack(spacing: 16) {
                        AccountAvatar(
                            image: account.avatar, url: account.profile.imageURL, revision: account.profileImageRevision
                        )
                        VStack(alignment: .leading, spacing: 8) {
                            Text(account.profile.name.isEmpty ? "—" : account.profile.name)
                                .font(AppFont.extraBold(size: 18))
                            HStack(spacing: 4) {
                                profileIcon(.accountCalendar, size: 14)
                                Text(membershipDate)
                                    .font(AppFont.regular(size: 12))
                            }
                            .foregroundStyle(AppColor.secondaryText)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        ProfileDirectionalIcon(asset: .accountForward)
                            .frame(width: 32, height: 32)
                    }
                }
            }
            .buttonStyle(.plain)
            HStack(spacing: 12) {
                CardContainer(padding: 12) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("more.Cashback balance".localized)
                            .font(AppFont.medium(size: 11))
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text(viewModel.cashback.map { homeNumber($0.total, decimals: 2) } ?? "—")
                                .font(AppFont.black(size: 20))
                            Text("home.sar".localized)
                                .font(AppFont.regular(size: 11))
                                .foregroundStyle(AppColor.secondaryText)
                        }
                    }
                    .frame(maxWidth: .infinity, minHeight: 60, alignment: .leading)
                }
                CardContainer(padding: 12) {
                    HStack(spacing: 8) {
                        statistic("more.Offers used".localized, value: viewModel.stats?.usedOffersCount)
                        Divider()
                            .frame(height: 32)
                        statistic("more.Total orders".localized, value: viewModel.stats?.ordersCount)
                    }
                    .frame(minHeight: 60)
                }
            }
            CardContainer(padding: 0) {
                VStack(spacing: 0) {
                    ProfileAccountMenuRow(
                        title: "more.Payment methods".localized,
                        subtitle: "more.Manage your cards and payment methods".localized, icon: .accountPayment
                    ) {
                        moreCoordinator.show(.payments)
                    }
                    profileDivider
                    ProfileAccountMenuRow(
                        title: "more.Notifications".localized,
                        subtitle: "more.Manage notification preferences".localized, icon: .accountNotification
                    ) {
                        moreCoordinator.show(.notifications)
                    }
                    profileDivider
                    ProfileAccountMenuRow(
                        title: "more.Help and support".localized,
                        subtitle: "more.Manage your support tickets".localized, icon: .accountSupport
                    ) {
                        moreCoordinator.show(.tickets)
                    }
                    profileDivider
                    ProfileAccountMenuRow(
                        title: "more.Join us".localized, subtitle: "more.Become our partner".localized,
                        icon: .accountJoin
                    ) {
                        moreCoordinator.show(.join)
                    }
                    profileDivider
                    ProfileAccountMenuRow(
                        title: "more.Settings".localized, subtitle: "more.Account, language and security".localized,
                        icon: .accountSettings
                    ) {
                        moreCoordinator.show(.settings)
                    }
                }
            }
            Button {
                logout = true
            } label: {
                HStack(spacing: 8) {
                    Text("more.Log out".localized)
                        .font(AppFont.button)
                    profileIcon(.accountLogout, size: 18)
                }
                .foregroundStyle(AppColor.primary)
                .frame(maxWidth: .infinity, minHeight: 55)
                .background(AppColor.surface, in: RoundedRectangle(cornerRadius: 16))
            }
            .buttonStyle(.plain)
        }
        .disabled(signingOut)
        .overlay {
            if signingOut {
                BrandLoaderView(size: 56)
            }
        }
        .alert(
            "Error".localized,
            isPresented: Binding(
                get: {
                    logoutError != nil
                },
                set: {
                    if !$0 {
                        logoutError = nil
                    }
                })
        ) {
            Button("api.retry".localized) {
                performLogout()
            }
            Button("api.signOutLocally".localized) {
                appCoordinator.forgetSession()
            }
            Button("cancel_title".localized, role: .cancel) {}
        } message: {
            Text(logoutError ?? "")
        }
        .task {
            account.loadSession()
            guard appCoordinator.isLoggedIn, moreCoordinator.path.isEmpty else {
                return
            }
            await refreshAccount()
        }
        .sheet(isPresented: $logout) {
            AccountLogoutSheet(
                onConfirm: {
                    logout = false
                    performLogout()
                },
                onCancel: {
                    logout = false
                })
        }
    }
    private var membershipDate: String {
        guard let date = viewModel.stats?.memberSince, !date.isEmpty else {
            return "more.Joined date unavailable".localized
        }
        return String(format: "more.Member since".localized, date)
    }

    private func refreshAccount() async {
        await account.loadProfile()
        guard appCoordinator.isLoggedIn, !Task.isCancelled else {
            return
        }
        await viewModel.loadStats()
        guard appCoordinator.isLoggedIn, !Task.isCancelled else {
            return
        }
        await viewModel.loadCashback()
    }

    private func performLogout() {
        guard !signingOut else {
            return
        }
        signingOut = true
        logoutError = nil
        Task { @MainActor in
            defer {
                signingOut = false
            }
            do {
                try await appCoordinator.signOut()
            } catch is CancellationError {} catch {
                logoutError = error.localizedDescription
            }
        }
    }
    private func statistic(_ title: String, value: Int?) -> some View {
        VStack(spacing: 8) {
            Text(value.map { homeNumber($0) } ?? "—")
                .font(AppFont.black(size: 18))
                .foregroundStyle(AppColor.primary)
            Text(title)
                .font(AppFont.regular(size: 10))
                .foregroundStyle(AppColor.secondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct ProfileAccountMenuRow: View {
    let title: String
    let subtitle: String
    let icon: LOHAsset
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                AccountIcon(asset: icon)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(AppFont.bold(size: 13))
                        .foregroundStyle(AppColor.text)
                    Text(subtitle)
                        .font(AppFont.regular(size: 11))
                        .foregroundStyle(AppColor.secondaryText)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                ProfileDirectionalIcon(asset: .accountMenuArrow)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .frame(minHeight: 60)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

private struct GuestAccountView: View {
    @EnvironmentObject private var app: AppCoordinator
    @EnvironmentObject private var coordinator: MoreCoordinator

    var body: some View {
        AccountPage(title: "more.My account".localized, back: false, hidesTabBar: !coordinator.path.isEmpty) {
            CardContainer {
                VStack(spacing: 16) {
                    LOHAsset.person.image.resizable().scaledToFit().frame(width: 32, height: 32)
                        .foregroundStyle(AppColor.primary)
                        .frame(width: 72, height: 72)
                        .background(AppColor.accentSurface, in: Circle())
                        .accessibilityHidden(true)
                    Text(homeText("guestAccountTitle"))
                        .font(AppFont.bold(size: 20))
                    Text(homeText("loginAccountHint"))
                        .font(AppFont.regular(size: 14))
                        .foregroundStyle(AppColor.secondaryText)
                        .multilineTextAlignment(.center)
                    MainAppButton(title: homeText("login"), action: {
                        app.beginAuthentication()
                    }, variant: .action)
                    MainAppButton(title: homeText("register"), action: {
                        app.beginAuthentication(register: true)
                    }, variant: .outlined)
                }
                .frame(maxWidth: .infinity)
            }
            CardContainer(padding: 0) {
                VStack(spacing: 0) {
                    ProfileAccountMenuRow(title: "more.Payment methods".localized,
                        subtitle: "more.Manage your cards and payment methods".localized, icon: .accountPayment) {
                        coordinator.show(.payments)
                    }
                    profileDivider
                    ProfileAccountMenuRow(title: "more.Notifications".localized,
                        subtitle: "more.Manage notification preferences".localized, icon: .accountNotification) {
                        coordinator.show(.notifications)
                    }
                    profileDivider
                    ProfileAccountMenuRow(title: "more.Help and support".localized,
                        subtitle: "more.Manage your support tickets".localized, icon: .accountSupport) {
                        coordinator.show(.tickets)
                    }
                    profileDivider
                    ProfileAccountMenuRow(title: "more.Join us".localized,
                        subtitle: "more.Become our partner".localized, icon: .accountJoin) {
                        coordinator.show(.join)
                    }
                    profileDivider
                    ProfileAccountMenuRow(title: "more.Settings".localized,
                        subtitle: homeText("guestSettingsHint"), icon: .accountSettings) {
                        coordinator.show(.settings)
                    }
                }
            }
        }
    }
}
