import Foundation

struct MoreUserStats: Decodable, Equatable {
    let usedOffersCount: Int
    let ordersCount: Int
    let memberSince: String

    enum CodingKeys: String, CodingKey {
        case usedOffersCount = "used_offers_count"
        case ordersCount = "orders_count"
        case memberSince = "member_since"
    }
}
