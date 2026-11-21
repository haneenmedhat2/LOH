import Foundation

struct SupportTicketType: Decodable, Identifiable {
    let id: Int
    let name: String
}

struct AccountTicket: Decodable, Identifiable {
    let id: Int
    let reference: String
    let title: String
    let description: String
    let status: String
    let statusText: String?
    let isClosed: Bool
    let canUserReply: Bool
    let type: SupportTicketType?
    let orderID: Int?
    let order: TicketOrderOption?
    let createdAt: String?
    let updatedAt: String?
    var code: String { reference.hasPrefix("#") ? reference : "#" + reference }
    var category: String { type?.name ?? "" }

    enum CodingKeys: String, CodingKey {
        case id, title, description, status, order
        case reference = "ticket_num", code = "ticket_code", statusText = "status_text"
        case isClosed = "is_closed", type = "ticket_type"
        case canUserReply = "can_user_reply"
        case orderID = "order_id", createdAt = "created_at", updatedAt = "last_updated"
    }
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        guard let id = c.flexibleInt(.id), id > 0 else { throw APIError.invalidResponse }
        self.id = id
        reference = try c.decodeIfPresent(String.self, forKey: .reference)
            ?? c.decode(String.self, forKey: .code)
        title = try c.decode(String.self, forKey: .title)
        description = try c.decodeIfPresent(String.self, forKey: .description) ?? ""
        status = try c.decode(String.self, forKey: .status)
        statusText = try c.decodeIfPresent(String.self, forKey: .statusText)
        isClosed = status == "closed" || c.flexibleBool(.isClosed) == true
        canUserReply = c.flexibleBool(.canUserReply) ?? false
        type = try c.decodeIfPresent(SupportTicketType.self, forKey: .type)
        order = try c.decodeIfPresent(TicketOrderOption.self, forKey: .order)
        orderID = c.flexibleInt(.orderID).flatMap { $0 > 0 ? $0 : nil } ?? order?.id
        createdAt = try c.decodeIfPresent(String.self, forKey: .createdAt)
        updatedAt = try c.decodeIfPresent(String.self, forKey: .updatedAt)
    }
}

struct SupportTicketPagination: Decodable {
    let current: Int
    let pages: Int
    let total: Int
    enum CodingKeys: String, CodingKey { case current = "current_page", pages = "total_pages", total = "total_items" }
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        guard let current = c.flexibleInt(.current), let pages = c.flexibleInt(.pages), let total = c.flexibleInt(.total) else {
            throw APIError.invalidResponse
        }
        self.current = current; self.pages = pages; self.total = total
    }
}
struct SupportTicketPage: Decodable {
    let tickets: [AccountTicket]
    let pagination: SupportTicketPagination?
    let counts: [String: Int]?
}
struct SupportTicketDetail: Decodable {
    let ticket: AccountTicket
    let replies: [TicketReply]
    private enum CodingKeys: String, CodingKey { case ticket, messages }
    private struct ReplyPage: Decodable {
        let data: [TicketReply]
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        ticket = try container.decode(AccountTicket.self, forKey: .ticket)
        replies = try container.decodeIfPresent(ReplyPage.self, forKey: .messages)?.data ?? []
    }
}

struct TicketListFilter {
    var status = "all"
    var search = ""
    func matches(_ ticket: AccountTicket) -> Bool {
        (status == "all" || ticket.status == status) &&
        (search.isEmpty || ticket.title.localizedCaseInsensitiveContains(search) || ticket.reference.localizedCaseInsensitiveContains(search))
    }
}
