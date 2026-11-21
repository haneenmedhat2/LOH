import Foundation
import Combine

@MainActor
final class TicketListViewModel: ObservableObject {
    @Published var filter = TicketListFilter()
    @Published private(set) var tickets: [AccountTicket] = []
    @Published private(set) var counts: [String: Int] = [:]
    @Published private(set) var loading = false
    @Published private(set) var loaded = false
    @Published private(set) var error: String?
    @Published private(set) var hasMore = false
    @Published private(set) var total = 0
    let client: DefaultResponseHandler
    let currentToken: @MainActor () -> String?
    private(set) var sessionScope = UUID()
    private var generation = UUID()
    private var page = 0
    private var status: SupportTicketStatus = .all
    var filteredTickets: [AccountTicket] { tickets.filter(filter.matches) }

    init(client: DefaultResponseHandler = DefaultResponseHandler(),
         currentToken: @escaping @MainActor () -> String? = { UserDefaults.accessToken }) {
        self.client = client; self.currentToken = currentToken
    }
    func checkSession(_ token: String, scope: UUID) throws {
        try Task.checkCancellation()
        guard currentToken() == token, sessionScope == scope else { throw CancellationError() }
    }
    func reload(language: String) async {
        generation = UUID(); page = 0; tickets = []; counts = [:]; total = 0
        hasMore = false; loaded = false; loading = false
        status = SupportTicketStatus(rawValue: filter.status) ?? .all
        await loadMore(language: language)
    }
    func loadMore(language: String) async {
        guard !loading else { return }
        guard let token = currentToken() else { error = APIError.missingSession.localizedDescription; return }
        let generation = generation, scope = sessionScope, next = page + 1
        loading = true; error = nil
        defer { if self.generation == generation { loading = false } }
        do {
            let result: SupportTicketPage = try await client.data(
                from: try SupportTicketEndpoints.list(status: status, page: next, token: token), language: language)
            try checkSession(token, scope: scope)
            guard self.generation == generation else { return }
            if let pagination = result.pagination, pagination.current != next { throw APIError.invalidResponse }
            var ids = Set(tickets.map(\.id))
            tickets += result.tickets.filter { ids.insert($0.id).inserted }
            counts = result.counts ?? counts
            total = result.pagination?.total ?? tickets.count
            hasMore = !result.tickets.isEmpty && (result.pagination.map { $0.current < $0.pages } ?? false)
            page = next; loaded = true
        } catch {
            guard self.generation == generation, sessionScope == scope, currentToken() == token, !Task.isCancelled else { return }
            self.error = error.localizedDescription
        }
    }
    func cache(_ ticket: AccountTicket) {
        if let index = tickets.firstIndex(where: { $0.id == ticket.id }) { tickets[index] = ticket }
    }
    func resetSession() {
        sessionScope = UUID(); generation = UUID()
        tickets = []; counts = [:]; filter = TicketListFilter()
        loading = false; loaded = false; error = nil; hasMore = false; total = 0; page = 0
    }
}
