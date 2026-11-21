import Foundation

struct PurchaseLoadContext: Hashable {
    let filter: PurchaseFilter
    let language: String
    let token: String?
}
