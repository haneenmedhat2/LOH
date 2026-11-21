import Foundation

/// Prices are calculated in decimal currency units and rounded once per line item.
struct HomeCheckoutPricing {
    let offer: HomeOffer
    let quantity: Int

    var subtotal: Double { multiplied(offer.price) }
    var serviceFee: Double { multiplied(offer.serviceFee ?? 0) }
    var total: Double { multiplied(offer.payablePrice) }

    var isValid: Bool {
        (1...10).contains(quantity) && offer.available
            && [offer.price, offer.serviceFee ?? 0, offer.payablePrice]
                .allSatisfy {
                    $0.isFinite && $0 >= 0 && decimal($0) != nil
                }
    }

    private func multiplied(_ value: Double) -> Double {
        guard let value = decimal(value) else { return 0 }
        var amount = value * Decimal(quantity)
        var rounded = Decimal()
        NSDecimalRound(&rounded, &amount, 2, .plain)
        return NSDecimalNumber(decimal: rounded).doubleValue
    }

    private func decimal(_ value: Double) -> Decimal? {
        guard value.isFinite, value >= 0,
            let amount = Decimal(string: String(value), locale: Locale(identifier: "en_US_POSIX")),
            !amount.isNaN
        else { return nil }
        return amount
    }
}
