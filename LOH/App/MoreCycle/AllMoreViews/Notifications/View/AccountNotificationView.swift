import SwiftUI

struct AccountNotificationView: View {
    @EnvironmentObject private var account: AccountNotificationViewModel
    @EnvironmentObject private var requests: AccountRequestController
    var body: some View {
        AccountPage(title: "more.Notification settings".localized, headerHeight: 60,
                    onRefresh: { await account.loadNotifications() }) {
            AccountFlowIntro(
                title: "accountFlow.Be the first to know".localized,
                subtitle: "accountFlow.Choose notifications".localized, icon: "NotificationHero", compact: true)
            if !account.loaded && !requests.busy {
                Button("api.retry".localized) {
                    Task {
                        await account.loadNotifications()
                    }
                }
                .font(AppFont.medium(size: 14))
                .foregroundStyle(AppColor.primary)
            }
            VStack(alignment: .leading, spacing: 0) {
                sectionTitle("more.General notifications".localized)
                preference(
                    "more.Allow notifications".localized, subtitle: "accountFlow.Important updates".localized,
                    icon: "Bell",
                    value: Binding(
                        get: {
                            account.notifications
                        },
                        set: { value in
                            Task {
                                await account.setEnabled(value)
                            }
                        }))
            }
            .background(AppColor.surface, in: RoundedRectangle(cornerRadius: 16))
            VStack(alignment: .leading, spacing: 0) {
                sectionTitle("accountFlow.Notification types".localized)
                Divider()
                    .opacity(0.3)
                preference(
                    "more.New offers".localized, subtitle: "accountFlow.Nearby offers".localized,
                    icon: "Heart",
                    value: Binding(
                        get: {
                            account.offerNotifications
                        },
                        set: { value in
                            Task {
                                await account.setNotification(.newOffers, value: value)
                            }
                        }))
                Divider()
                    .opacity(0.3)
                preference(
                    "more.Order updates".localized, subtitle: "accountFlow.Payment and redemption".localized,
                    icon: "Document",
                    value: Binding(
                        get: {
                            account.orderNotifications
                        },
                        set: { value in
                            Task {
                                await account.setNotification(.orderUpdates, value: value)
                            }
                        }))
                Divider()
                    .opacity(0.3)
                preference(
                    "more.Offer reminders".localized, subtitle: "accountFlow.Expiry reminders".localized,
                    icon: "Bell",
                    value: Binding(
                        get: {
                            account.reminderNotifications
                        },
                        set: { value in
                            Task {
                                await account.setNotification(.offerReminders, value: value)
                            }
                        }))
            }
            .background(AppColor.surface, in: RoundedRectangle(cornerRadius: 16))
            HStack(spacing: 8) {
                Text("accountFlow.Device notification settings".localized)
                    .font(AppFont.regular(size: 12))
                    .foregroundStyle(AppColor.mutedText)
                AccountFlowIcon(name: "Shield", size: 14)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
        .task {
            await account.loadNotifications()
        }
    }
    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(AppFont.bold(size: 12))
            .foregroundStyle(AppColor.secondaryText)
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 6)
    }
    private func preference(_ title: String, subtitle: String, icon: String, value: Binding<Bool>) -> some View {
        Toggle(isOn: value) {
            HStack(spacing: 12) {
                AccountFlowIcon(name: icon)
                    .frame(width: 32, height: 32)
                    .background(AppColor.accountCanvas, in: RoundedRectangle(cornerRadius: 12))
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(AppFont.bold(size: 13))
                    Text(subtitle)
                        .font(AppFont.regular(size: 11))
                        .foregroundStyle(AppColor.secondaryText)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .toggleStyle(AccountNotificationToggleStyle())
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .disabled(!account.loaded)
    }
}

private struct AccountNotificationToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 12) {
            configuration.label
            Button {
                configuration.isOn.toggle()
            } label: {
                Capsule()
                    .fill(configuration.isOn ? AppColor.primary : Color(.systemGray4))
                    .frame(width: 50, height: 28)
                    .overlay(alignment: configuration.isOn ? .trailing : .leading) {
                        Circle()
                            .fill(.white)
                            .frame(width: 20, height: 20)
                            .shadow(color: .black.opacity(0.1), radius: 2, y: 1)
                            .padding(4)
                    }
                    .environment(\.layoutDirection, .leftToRight)
                    .frame(minHeight: 44)
            }
            .buttonStyle(.plain)
        }
        .accessibilityRepresentation {
            Toggle(
                isOn: Binding(
                    get: {
                        configuration.isOn
                    },
                    set: {
                        configuration.isOn = $0
                    })
            ) {
                configuration.label
            }
            .toggleStyle(.switch)
        }
    }
}
