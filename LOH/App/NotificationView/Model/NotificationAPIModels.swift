import Foundation

struct NotificationCount: Decodable {
    let count: Int
    private enum CodingKeys: String, CodingKey { case count }
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        guard let count = container.flexibleInt(.count), count >= 0 else { throw APIError.invalidResponse }
        self.count = count
    }
}

struct NotificationStatus: Decodable {
    let notify: Bool
    private enum CodingKeys: String, CodingKey { case notify }
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        guard let notify = container.flexibleBool(.notify) else { throw APIError.invalidResponse }
        self.notify = notify
    }
}
