import Foundation


@MainActor
final class MoreAccountStore {
    let requests: AccountRequestController
    let more: MoreViewModel
    let profile: AccountProfileViewModel
    let payments: PaymentCardViewModel
    let tickets: TicketListViewModel
    let notifications: AccountNotificationViewModel
    let language: AccountLanguageViewModel

    init() {
        let requests = AccountRequestController()
        self.requests = requests
        more = MoreViewModel(requests: requests)
        profile = AccountProfileViewModel(requests: requests)
        payments = PaymentCardViewModel(requests: requests)
        tickets = TicketListViewModel(currentToken: { UserDefaults.accessToken })
        notifications = AccountNotificationViewModel(requests: requests)
        language = AccountLanguageViewModel(requests: requests)
    }

    func resetSession() {
        requests.resetSession()
        more.resetSession()
        profile.resetSession()
        payments.resetSession()
        tickets.resetSession()
        notifications.resetSession()
        language.resetSession()
        AuthPreviewSession.user = nil
    }
}
