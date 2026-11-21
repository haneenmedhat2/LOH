import Foundation
import Combine

@MainActor
final class AccountNotificationViewModel: ObservableObject {
    @Published var notifications = true
    @Published var offerNotifications = true
    @Published var orderNotifications = true
    @Published var reminderNotifications = true
    @Published private(set) var loaded = false
    let requests: AccountRequestController
    init(requests: AccountRequestController) {
        self.requests = requests
    }

    func loadNotifications() async {
        await requests.run { token, generation in
            async let prefs: AccountNotificationPreferences = requests.client.data(
                from: NotificationEndpoints.settings(token: token), language: requests.language)
            async let user: APIUser = requests.client.data(
                from: AuthEndpoints.profile(token: token), language: requests.language)
            let result = try await (prefs, user)
            try requests.check(token, generation)
            notifications = result.1.isNotify ?? false
            offerNotifications = result.0.newOffers; orderNotifications = result.0.orderUpdates; reminderNotifications = result.0.offerReminders
            loaded = true
        }
    }
    func setEnabled(_ value: Bool) async {
        guard loaded, value != notifications else { return }
        await requests.run { token, generation in
            let result: NotificationStatus = try await requests.client.data(
                from: NotificationEndpoints.switchStatus(token: token), language: requests.language)
            let settings: AccountNotificationPreferences = try await requests.client.data(
                from: NotificationEndpoints.settings(token: token), language: requests.language)
            try requests.check(token, generation)
            notifications = result.notify
            offerNotifications = settings.newOffers
            orderNotifications = settings.orderUpdates
            reminderNotifications = settings.offerReminders
        }
    }
    func setNotification(_ key: AccountNotificationPreferenceKey, value: Bool) async {
        guard loaded else { return }
        await requests.run { token, generation in
            try await requests.client.perform(
                NotificationEndpoints.update(key, value: value, token: token), language: requests.language)
            try requests.check(token, generation)
            switch key {
            case .newOffers: offerNotifications = value
            case .orderUpdates: orderNotifications = value
            case .offerReminders: reminderNotifications = value
            }
        }
    }

    func resetSession() {
        notifications = true; offerNotifications = true
        orderNotifications = true; reminderNotifications = true
        loaded = false
    }
}
