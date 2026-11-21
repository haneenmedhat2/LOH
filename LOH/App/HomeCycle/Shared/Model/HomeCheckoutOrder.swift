import Foundation

/// An immutable order submission. `amount` is the selected coupon quantity.
struct HomeCheckoutOrder: Hashable, Identifiable {
    let id: UUID
    let offer: HomeOffer
    let quantity: Int
    let paymentType: HomeOrderPaymentType

    init(offer: HomeOffer, quantity: Int, paymentType: HomeOrderPaymentType, id: UUID = UUID()) {
        self.id = id
        self.offer = offer
        self.quantity = quantity
        self.paymentType = paymentType
    }

    var pricing: HomeCheckoutPricing { HomeCheckoutPricing(offer: offer, quantity: quantity) }
}

enum HomeOrderPaymentType: String, CaseIterable {
    case visa, master, mada, stcpay, applepay, cashback

    var titleKey: String {
        switch self {
        case .visa: return "visa"
        case .master: return "mastercard"
        case .mada: return "mada"
        case .stcpay: return "stcPay"
        case .applepay: return "applePay"
        case .cashback: return "cashback"
        }
    }

    static func cardBrand(_ brand: String) -> Self? {
        switch brand.lowercased().replacingOccurrences(of: " ", with: "") {
        case "visa": return .visa
        case "master", "mastercard": return .master
        case "mada": return .mada
        default: return nil
        }
    }
}
