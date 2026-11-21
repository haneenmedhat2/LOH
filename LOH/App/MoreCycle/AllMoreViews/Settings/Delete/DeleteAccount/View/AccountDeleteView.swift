import SwiftUI

struct AccountDeleteView: View {
    @EnvironmentObject private var requests: AccountRequestController
    @StateObject var account: AccountDeleteViewModel
    @EnvironmentObject private var coordinator: MoreCoordinator
    @EnvironmentObject private var appCoordinator: AppCoordinator
    var body: some View {
        introduction
            .navigationDestination(
                isPresented: Binding(
                    get: {
                        account.step != .introduction
                    },
                    set: {
                        if !$0 && account.step == .confirmation {
                            account.step = .introduction
                        }
                    }
                )
            ) {
                Group {
                    if account.step == .completed {
                        AccountDeletedView {
                            appCoordinator.forgetSession()
                        }
                    } else if account.step == .processing {
                        AccountDeletionProcessingView()
                    } else {
                        confirmation
                    }
                }
            }
    }
    private var introduction: some View {
        AccountPage(
            title: "more.Delete account".localized, headerHeight: 36,
            headerBackground: AppColor.canvas, canvas: AppColor.canvas
        ) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("settings.Leaving title".localized)
                        .font(AppFont.black(size: 15))
                    Text("more.We are sorry to see you go. Review the details before continuing.".localized)
                        .font(AppFont.regular(size: 10))
                        .foregroundStyle(AppColor.secondaryText)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                ZStack(alignment: .topLeading) {
                    SettingsIcon(name: "DeletePerson", width: 38)
                    SettingsIcon(name: "DeleteBin", width: 28, height: 32)
                        .offset(x: 36, y: 24)
                }
                .frame(width: 64, height: 56)
                .environment(\.layoutDirection, .leftToRight)
            }
            .padding(12)
            .background(deleteGradient, in: RoundedRectangle(cornerRadius: 16))
            Text("more.What happens when you delete your account?".localized)
                .font(AppFont.extraBold(size: 13))
            VStack(spacing: 8) {
                consequence("more.Your profile and account data will be deleted", icon: "DeleteProfile")
                consequence("more.Unused purchased offers will be lost", icon: "DeleteTag")
                consequence("more.Remaining cashback will be lost", icon: nil)
                consequence("more.Deletion cannot be undone after confirmation", icon: "DeleteWarning")
            }
            SettingsWarning(title: "more.Before continuing".localized, message: "settings.Use balances first".localized)
            VStack(alignment: .leading, spacing: 4) {
                Text("settings.Help improve".localized)
                    .font(AppFont.extraBold(size: 13))
                Text("settings.Multiple reasons".localized)
                    .font(AppFont.regular(size: 11))
                    .foregroundStyle(AppColor.mutedText)
            }
            VStack(spacing: 8) {
                ForEach(account.reasonKeys, id: \.self) { reason in
                    Button {
                        if account.reasons.contains(reason) {
                            account.reasons.remove(reason)
                        } else {
                            account.reasons.insert(reason)
                        }
                    } label: {
                        HStack(spacing: 12) {
                            RoundedRectangle(cornerRadius: 5)
                                .strokeBorder(
                                    account.reasons.contains(reason) ? AppColor.primary : AppColor.border, lineWidth: 1
                                )
                                .frame(width: 20, height: 20)
                                .background(
                                    account.reasons.contains(reason) ? AppColor.primary : AppColor.surface,
                                    in: RoundedRectangle(cornerRadius: 5)
                                )
                                .overlay {
                                    if account.reasons.contains(reason) {
                                        Image("lohPasswordChangedCheck")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 12, height: 12)
                                    }
                                }
                            Text(reason.localized)
                                .font(AppFont.regular(size: 12))
                                .foregroundStyle(AppColor.text)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(12)
                        .background(AppColor.surface, in: RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(account.reasons.contains(reason) ? .isSelected : [])
                }
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            VStack(spacing: 8) {
                MainAppButton(
                    title: "more.Keep my account".localized,
                    action: {
                        coordinator.pop()
                    }, height: 44)
                MainAppButton(
                    title: "more.Continue deleting account".localized,
                    action: {
                        account.step = .confirmation
                    }, variant: .secondary, height: 46)
                HStack(spacing: 4) {
                    SettingsIcon(name: "DeleteFooter", width: 10)
                    Text("settings.Delete confirmation note".localized)
                        .font(AppFont.regular(size: 10))
                        .foregroundStyle(AppColor.mutedText)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(AppColor.surface)
        }
    }
    private func consequence(_ key: String, icon: String?) -> some View {
        HStack(spacing: 12) {
            Group {
                if let icon {
                    SettingsIcon(name: icon, width: 16)
                } else {
                    Text("SR")
                        .font(.system(size: 9, weight: .black))
                        .foregroundStyle(AppColor.primary)
                        .frame(width: 16, height: 16)
                        .overlay(
                            Circle()
                                .stroke(AppColor.primary))
                }
            }
            .frame(width: 36, height: 36)
            .background(AppColor.accentSurface, in: RoundedRectangle(cornerRadius: 12))
            Text(key.localized)
                .font(AppFont.regular(size: 12))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(AppColor.surface, in: RoundedRectangle(cornerRadius: 16))
    }
    private var deleteGradient: LinearGradient {
        LinearGradient(
            colors: [AppColor.accentSurface, AppColor.surface], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
    private var confirmation: some View {
        AccountPage(title: "more.Confirm account deletion".localized, hidesTabBar: true) {
            SettingsWarning(
                title: "more.Delete account".localized,
                message: "more.Deletion cannot be undone after confirmation".localized)
            MainAppButton(
                title: "more.Delete account".localized,
                action: {
                    Task {
                        if await account.deleteAccount() {
                            // Keep the completion screen visible while removing cached account data.
                            appCoordinator.clearSessionData()
                        }
                    }
                }, variant: .action, isEnabled: !requests.busy)
            MainAppButton(
                title: "more.Keep my account".localized,
                action: {
                    coordinator.pop()
                }, variant: .secondary)
        }
    }
}
