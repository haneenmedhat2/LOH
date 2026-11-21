//
//  ProfileCoordinator.swift
//  CTF
//
//  Created by Mohamed Hadwa on 17/11/2025.
//

// MoreCoordinator.swift
import SwiftUI

@MainActor
final class MoreCoordinator: BaseCoordinator<MoreCoordinatorRoute> {
    let account = MoreAccountStore()
    @Published var showsLogin = false
    private(set) var loginRoute: MoreCoordinatorRoute?
    @Published var modalRoute: MoreModalRoute?

    @ViewBuilder
    func destination(for route: MoreCoordinatorRoute) -> some View {
        switch route {
        case .settings:
            AccountSettingsView()
                .logScreen("AccountSettingsView")
        case .editProfile:
            AccountProfileView()
                .logScreen("AccountProfileView")
        case .payments:
            PaymentCardView()
                .logScreen("PaymentCardView")
        case .addCard:
            AddPaymentCardView()
                .logScreen("AddPaymentCardView")
        case .notifications:
            AccountNotificationView()
                .logScreen("AccountNotificationView")
        case .tickets:
            AccountTicketsView()
                .logScreen("AccountTicketsView")
        case .faqs:
            FAQListView()
                .logScreen("FAQListView")
        case .faqDetail(let id):
            FAQDetailView(id: id)
                .logScreen("FAQDetailView")
        case .newTicket:
            AccountNewTicketView()
                .logScreen("AccountNewTicketView")
        case .ticket(let id):
            AccountTicketDetailView(id: id)
                .logScreen("AccountTicketDetailView")
        case .purchaseDetail(let id):
            PurchaseDetailView(id: id, status: nil)
        case .join:
            AccountJoinView(viewModel: AccountJoinViewModel(requests: self.account.requests))
                .logScreen("AccountJoinView")
        case .password:
            AccountPasswordView(viewModel: AccountPasswordViewModel(requests: self.account.requests))
                .logScreen("AccountPasswordView")
        case .language:
            AccountLanguageView()
                .logScreen("AccountLanguageView")
        case .security:
            AccountSecurityView()
                .logScreen("AccountSecurityView")
        case .document(let document):
            AccountDocumentView(document: document)
                .logScreen("AccountDocumentView")
        case .deleteAccount:
            AccountDeleteView(account: AccountDeleteViewModel(requests: self.account.requests))
                .logScreen("AccountDeleteView")
        }
    }

    func show(_ route: MoreCoordinatorRoute) {
        if UserDefaults.accessToken == nil && route.requiresAccount {
            loginRoute = route
            showsLogin = true
            return
        }
        path.append(route)
    }

    func present(_ modal: MoreModalRoute) {
        modalRoute = modal
    }

    func dismissModal() {
        modalRoute = nil
    }
}
