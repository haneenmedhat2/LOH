import Foundation

struct SupportTicketEndpoints {
    private init() {}
}

extension SupportTicketEndpoints {
    static
    func types(token: String) -> Endpoint<APIEnvelope<[SupportTicketType]>> {
        return Endpoint(
            path: "ticket-types",
            headerType: .authorized(token: token)
        )
    }
    static
    func orders(token: String) -> Endpoint<APIEnvelope<[TicketOrderOption]>> {
        Endpoint(
            path: "orders",
            headerType: .authorized(token: token)
        )
    }
    static
    func list(status: SupportTicketStatus, page: Int, token: String) throws -> Endpoint<APIEnvelope<SupportTicketPage>> {
        guard page > 0 else { throw APIError.invalidResponse }
        return Endpoint(
            path: "my-tickets",
            queries: ["status": status.rawValue, "page": page],
            headerType: .authorized(token: token)
        )
    }
    static
    func detail(id: Int, token: String) throws -> Endpoint<APIEnvelope<SupportTicketDetail>> {
        guard id > 0 else { throw APIError.invalidResponse }
        return Endpoint(
            path: "my-tickets/\(id)",
            headerType: .authorized(token: token),
            cachePolicy: .reloadIgnoringLocalCacheData,
            timeoutInterval: 20
        )
    }
    static
    func reply(id: Int, text: String, token: String) throws -> Endpoint<APIEnvelope<APIEmpty>> {
        let text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard id > 0, (2...5000).contains(text.count) else { throw APIError.invalidResponse }
        return Endpoint(
            method: .post,
            path: "my-tickets/\(id)/reply",
            body: ["replay": text],
            headerType: .authorized(token: token)
        )
    }
    static
    func create(_ submission: SupportTicketSubmission, token: String) throws -> Endpoint<APIEnvelope<AccountTicket>> {
        guard submission.isValid else { throw APIError.invalidResponse }
        var fields = [
            ("ticket_type_id", String(submission.typeID)),
            ("title", submission.title.trimmingCharacters(in: .whitespacesAndNewlines)),
            ("description", submission.description.trimmingCharacters(in: .whitespacesAndNewlines))
        ]
        if let id = submission.orderID { fields.append(("order_id", String(id))) }
        let body = fields.reduce(into: APIParameters()) { parameters, field in
            parameters[field.0] = field.1
        }
        return Endpoint(
            method: .post,
            path: "send-ticket",
            body: body,
            headerType: .authorized(token: token)
        )
    }
}
