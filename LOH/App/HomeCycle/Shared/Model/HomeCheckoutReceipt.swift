import Foundation

/// A server acknowledgement or an explicitly constructed, non-redeemable design preview.
struct HomeCheckoutReceipt: Hashable {
    let offer: HomeOffer
    let quantity: Int
    let method: String
    let id: UUID
    let result: HomeCreateOrderResult?
    var isPreview: Bool { result == nil }
    var purchases: [PurchaseDetail] { result?.data?.offers ?? [] }
    var total: Double {
        // Each voucher can repeat the same order total. Do not sum or multiply it.
        purchases.compactMap { $0.order?.paidAmount }.first
            ?? HomeCheckoutPricing(offer: offer, quantity: quantity).total
    }
    var code: String? {
        guard isPreview else { return nil }
        return "DEMO-" + String(id.uuidString.replacingOccurrences(of: "-", with: "").prefix(8))
    }
    var qrPayload: String? {
        code.map { "LOH-DEMO-NOT-REDEEMABLE:\($0)" }
    }

    init(order: HomeCheckoutOrder, result: HomeCreateOrderResult) {
        offer = order.offer
        quantity = order.quantity
        method = order.paymentType.titleKey
        id = order.id
        self.result = result
    }

    init(offer: HomeOffer, quantity: Int, method: String, id: UUID = UUID()) {
        self.offer = offer
        self.quantity = min(10, max(1, quantity))
        self.method = method
        self.id = id
        result = nil
    }
}
