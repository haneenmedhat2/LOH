import Foundation

enum AccountNotificationPreferenceKey: String, CaseIterable {
    case newOffers = "new_offers", orderUpdates = "order_updates", offerReminders = "offer_reminders"
}

struct AccountNotificationPreferences: Decodable {
    let newOffers: Bool
    let orderUpdates: Bool
    let offerReminders: Bool
    enum CodingKeys: String, CodingKey { case newOffers = "new_offers", orderUpdates = "order_updates", offerReminders = "offer_reminders" }
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        guard let offers = c.flexibleBool(.newOffers), let orders = c.flexibleBool(.orderUpdates),
              let reminders = c.flexibleBool(.offerReminders) else { throw APIError.invalidResponse }
        newOffers = offers; orderUpdates = orders; offerReminders = reminders
    }
}
