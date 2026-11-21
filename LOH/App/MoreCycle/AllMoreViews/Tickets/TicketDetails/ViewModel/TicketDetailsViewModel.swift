import Foundation
import Combine

@MainActor
final class TicketDetailsViewModel: ObservableObject {
    @Published var replyText = ""
    @Published private(set) var ticket: AccountTicket?
    @Published private(set) var replies: [TicketReply] = []
    @Published private(set) var loading = false
    @Published private(set) var error: String?
    @Published private(set) var sending = false
    @Published private(set) var sendError: String?
    private var generation = UUID()
    var canReply: Bool { ticket?.canUserReply == true }
    var canSend: Bool {
        let text = replyText.trimmingCharacters(in: .whitespacesAndNewlines)
        return canReply && ticket != nil && !sending && !loading && (2...5000).contains(text.count)
    }


    func load(id: Int, using account: TicketListViewModel, language: String) async {
        guard let token = account.currentToken() else { error = APIError.missingSession.localizedDescription; return }
        let scope = account.sessionScope, generation = UUID()
        self.generation = generation
        loading = true; error = nil
        defer { if self.generation == generation { loading = false } }
        do {
            let result: SupportTicketDetail = try await account.client.data(
                from: try SupportTicketEndpoints.detail(id: id, token: token), language: language)
            guard result.ticket.id == id else { throw APIError.invalidResponse }
            try account.checkSession(token, scope: scope)
            guard self.generation == generation else { return }
            ticket = result.ticket
            var ids = Set<Int>()
            replies = result.replies.filter { ids.insert($0.id).inserted }
                .sorted { ($0.date ?? "", $0.id) < ($1.date ?? "", $1.id) }
            account.cache(result.ticket)
        } catch {
            guard self.generation == generation, account.sessionScope == scope, account.currentToken() == token, !Task.isCancelled else { return }
            self.error = error.localizedDescription
        }
    }

    func send(id: Int, using account: TicketListViewModel, language: String) async {
        guard canSend, ticket?.id == id else { return }
        guard let token = account.currentToken() else {
            sendError = APIError.missingSession.localizedDescription
            return
        }
        let scope = account.sessionScope, text = replyText
        sending = true; sendError = nil
        defer { sending = false }
        do {
            try await account.client.perform(
                try SupportTicketEndpoints.reply(id: id, text: text, token: token), language: language)
            try account.checkSession(token, scope: scope)
            if replyText == text { replyText = "" }
            await load(id: id, using: account, language: language)
        } catch {
            guard account.sessionScope == scope, account.currentToken() == token, !Task.isCancelled else { return }
            sendError = error.localizedDescription
        }
    }
}
