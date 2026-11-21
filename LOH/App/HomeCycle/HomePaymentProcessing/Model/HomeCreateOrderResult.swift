import Foundation

/// Confirmed payment data, including every purchased voucher returned by the server.
struct HomeCreateOrderResult: Hashable {
    let message: String?
    let data: HomeCreatedOrderData?

    init(message: String?, data: HomeCreatedOrderData? = nil) {
        self.message = message
        self.data = data
    }
}

struct HomeCreatedOrderData: Decodable, Hashable {
    let orderID: Int
    let offers: [PurchaseDetail]

    private enum CodingKeys: String, CodingKey {
        case orderID = "order_id", offers
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        guard let orderID = container.flexibleInt(.orderID), orderID > 0 else {
            throw APIError.invalidResponse
        }
        self.orderID = orderID
        offers = try container.decode([PurchaseDetail].self, forKey: .offers)
        guard Set(offers.map(\.id)).count == offers.count,
            offers.allSatisfy({ $0.order?.id == nil || $0.order?.id == orderID })
        else { throw APIError.invalidResponse }
    }
}
