enum MoreCoordinatorRoute: Hashable {
    case settings
    case editProfile
    case payments, addCard, notifications, tickets, newTicket, join, faqs
    case faqDetail(Int)
    case ticket(Int)
    case purchaseDetail(Int)
    case password, language, security, document(AccountDocument), deleteAccount
}

extension MoreCoordinatorRoute {
    var requiresAccount: Bool {
        switch self {
        case .settings, .language, .security, .document, .faqs, .faqDetail: return false
        default: return true
        }
    }
}
