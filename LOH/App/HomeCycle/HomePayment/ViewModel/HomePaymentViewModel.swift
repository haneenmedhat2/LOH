import Combine
import Foundation

@MainActor
final class HomePaymentViewModel: ObservableObject {
    let offer: HomeOffer
    let quantity: Int
    @Published private(set) var method: HomePaymentMethod = .applePay
    @Published private(set) var selectedCardID: Int?
    private var selectedCardType: HomeOrderPaymentType?
    @Published var error: String?
    @Published private(set) var isContinuing = false

    init(offer: HomeOffer, quantity: Int) {
        self.offer = offer
        self.quantity = quantity
    }

    var pricing: HomeCheckoutPricing { HomeCheckoutPricing(offer: offer, quantity: quantity) }

    func select(_ method: HomePaymentMethod) {
        self.method = method
        selectedCardID = nil
        selectedCardType = nil
    }

    func selectCard(_ card: AccountCard) {
        guard let type = HomeOrderPaymentType.cardBrand(card.brand) else { return }
        method = type == .mada ? .mada : .card
        selectedCardID = selectedCardID == card.id ? nil : card.id
        selectedCardType = selectedCardID == nil ? nil : type
    }

    func resumeSelection() { isContinuing = false }

    func makeOrder() -> HomeCheckoutOrder? {
        guard !isContinuing else { return nil }
        guard pricing.isValid, offer.isRemote, let id = Int(offer.id), id > 0 else {
            error = NSLocalizedString("home.checkoutInvalidOffer", comment: "")
            return nil
        }
        let type: HomeOrderPaymentType
        switch method {
        case .applePay: type = .applepay
        case .mada: type = .mada
        // The general card option keeps the API's existing visa default.
        // A saved Mastercard supplies its brand without a separate picker.
        case .card: type = selectedCardType == .master ? .master : .visa
        case .cashback: type = .cashback
        }
        isContinuing = true
        return HomeCheckoutOrder(offer: offer, quantity: quantity, paymentType: type)
    }
}
