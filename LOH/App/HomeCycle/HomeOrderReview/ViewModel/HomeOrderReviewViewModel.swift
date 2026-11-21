import Combine
import Foundation

@MainActor
final class HomeOrderReviewViewModel: ObservableObject {
    let offer: HomeOffer
    @Published private(set) var quantity = 1

    init(offer: HomeOffer) { self.offer = offer }

    var pricing: HomeCheckoutPricing { HomeCheckoutPricing(offer: offer, quantity: quantity) }
    var canContinue: Bool { pricing.isValid }

    func increaseQuantity() { quantity = min(10, quantity + 1) }
    func decreaseQuantity() { quantity = max(1, quantity - 1) }
}
