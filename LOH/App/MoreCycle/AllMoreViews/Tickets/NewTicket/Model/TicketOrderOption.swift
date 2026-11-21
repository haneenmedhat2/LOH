import Foundation

struct TicketOrderOption: Decodable, Identifiable {
    let id: Int
    let number: String?

    var label: String {
        guard let number, !number.isEmpty else { return "#\(id)" }
        return number.hasPrefix("#") ? number : "#\(number)"
    }

    private enum CodingKeys: String, CodingKey {
        case id, number, orderNumber = "order_number", orderNum = "order_num", orderCode = "order_code"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        guard let id = container.flexibleInt(.id), id > 0 else { throw APIError.invalidResponse }
        self.id = id
        number = Self.value(container, for: .orderCode)
            ?? Self.value(container, for: .orderNumber)
            ?? Self.value(container, for: .orderNum)
            ?? Self.value(container, for: .number)
    }

    private static func value(_ container: KeyedDecodingContainer<CodingKeys>, for key: CodingKeys) -> String? {
        if let value = try? container.decode(String.self, forKey: key) { return value }
        return container.flexibleInt(key).map(String.init)
    }
}
