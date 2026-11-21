import Foundation

enum HomePaymentMethod: String, CaseIterable, Identifiable {
    case applePay, mada, card, cashback
    var id: String { rawValue }
}
