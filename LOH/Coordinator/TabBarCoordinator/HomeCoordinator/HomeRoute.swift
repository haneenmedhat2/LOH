import Foundation

enum HomeRoute: Hashable {
    case feed(HomeOfferFeed, Int?)
    case offerID(String)
    case search
    case results(String, OfferCategory)
    case offer(HomeOffer)
    case merchant(HomeOffer)
    case merchantID(Int)
    case review(HomeOffer)
    case payment(HomeOffer, Int)
    case paymentProcessing(HomeCheckoutOrder)
    case paymentSuccess(HomeCheckoutReceipt)
    case qrCode(HomeCheckoutReceipt)
    case purchaseCode(id: Int, status: PurchaseStatus?)
    case favorites
    case notifications
}
