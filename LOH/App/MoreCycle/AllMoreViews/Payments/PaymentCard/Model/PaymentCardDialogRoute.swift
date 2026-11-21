import Foundation

enum PaymentCardDialogRoute: Identifiable {
    case delete(AccountCard), rename(AccountCard)
    var id: String {
        switch self {
        case .delete(let card): return "delete-" + String(card.id)
        case .rename(let card): return "rename-" + String(card.id)
        }
    }
}
