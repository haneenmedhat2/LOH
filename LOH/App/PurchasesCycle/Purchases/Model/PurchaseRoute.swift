import Foundation

struct PurchaseRoute: Hashable {
    let id: Int
    let status: PurchaseStatus?
    var codeOnly = false
}
