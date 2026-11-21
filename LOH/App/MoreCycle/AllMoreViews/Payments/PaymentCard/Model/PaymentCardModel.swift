import Foundation

/// Full card numbers and security codes are never retained.
struct AccountCard: Identifiable, Decodable {
    let id: Int
    let lastFour: String
    let brand: String
    let expiry: String
    var isDefault: Bool
    var nickname = ""

    enum CodingKeys: String, CodingKey {
        case id, brand, expiry, type
        case lastFour = "last_four", last4, cardNumber = "card_number", cardType = "card_type"
        case isDefault = "is_default", holderName = "holder_name"
    }
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        guard let id = c.flexibleInt(.id), let isDefault = c.flexibleBool(.isDefault) else { throw APIError.invalidResponse }
        self.id = id; self.isDefault = isDefault
        let masked = try c.decodeIfPresent(String.self, forKey: .lastFour)
            ?? c.decodeIfPresent(String.self, forKey: .last4)
            ?? c.decodeIfPresent(String.self, forKey: .cardNumber) ?? ""
        lastFour = String(AccountValidation.digits(masked).suffix(4))
        guard lastFour.count == 4 else { throw APIError.invalidResponse }
        brand = (try c.decodeIfPresent(String.self, forKey: .brand)
            ?? c.decodeIfPresent(String.self, forKey: .cardType)
            ?? c.decodeIfPresent(String.self, forKey: .type) ?? "card").lowercased()
        expiry = try c.decodeIfPresent(String.self, forKey: .expiry) ?? ""
        nickname = try c.decodeIfPresent(String.self, forKey: .holderName) ?? ""
    }
}

/// Only masked display metadata is retained after decoding a saved card.
struct AccountCardList: Decodable {
    let cards: [AccountCard]
    enum CodingKeys: String, CodingKey { case cards, data }
    init(from decoder: Decoder) throws {
        if let array = try? decoder.singleValueContainer().decode([AccountCard].self) { cards = array; return }
        let c = try decoder.container(keyedBy: CodingKeys.self)
        if c.contains(.cards) { cards = try c.decode([AccountCard].self, forKey: .cards) }
        else { cards = try c.decode([AccountCard].self, forKey: .data) }
    }
}
