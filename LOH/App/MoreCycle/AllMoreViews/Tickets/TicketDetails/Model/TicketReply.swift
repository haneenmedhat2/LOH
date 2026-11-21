import Foundation

struct TicketReply: Decodable, Identifiable {
    let id: Int
    let text: String
    let isSupport: Bool
    let date: String?
    let relativeDate: String?

    init(id: Int, text: String, isSupport: Bool, date: String? = nil, relativeDate: String? = nil) {
        self.id = id
        self.text = text
        self.isSupport = isSupport
        self.date = date
        self.relativeDate = relativeDate
    }

    private enum CodingKeys: String, CodingKey {
        case id, body, sender, isSender = "is_sender", date = "created_at", relativeDate = "created_dt"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        guard let id = container.flexibleInt(.id) else { throw APIError.invalidResponse }
        self.id = id
        text = try container.decode(String.self, forKey: .body)
        if let isSender = container.flexibleBool(.isSender) {
            isSupport = !isSender
        } else {
            isSupport = try container.decodeIfPresent(String.self, forKey: .sender) != "user"
        }
        date = try container.decodeIfPresent(String.self, forKey: .date)
        relativeDate = try container.decodeIfPresent(String.self, forKey: .relativeDate)
    }

    func timeText(language: String) -> String? {
        guard let date else { return relativeDate }
        let input = DateFormatter()
        input.locale = Locale(identifier: "en_US_POSIX")
        input.dateFormat = "yyyy-MM-dd HH:mm:ss"
        guard let value = input.date(from: date) ?? ISO8601DateFormatter().date(from: date) else {
            return relativeDate ?? date
        }
        let output = DateFormatter()
        output.locale = Locale(identifier: language)
        output.dateFormat = "h:mm a"
        return output.string(from: value)
    }
}
