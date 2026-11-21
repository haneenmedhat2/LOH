import Foundation
import Combine

@MainActor
final class NewTicketViewModel: ObservableObject {
    @Published var form = NewTicketForm()
    @Published private(set) var types: [SupportTicketType] = []
    @Published private(set) var orders: [TicketOrderOption] = []
    @Published private(set) var loadingTypes = false
    @Published private(set) var loadingOrders = false
    @Published private(set) var submitting = false
    @Published private(set) var error: String?
    @Published private(set) var ordersError: String?
    @Published private(set) var createdTicket: AccountTicket?
    var createdID: Int? { createdTicket?.id }
    private var typesGeneration = UUID()
    private var ordersGeneration = UUID()
    var canSubmit: Bool {
        form.valid && types.contains { String($0.id) == form.category }
            && (form.relatedOrder.isEmpty || orders.contains { String($0.id) == form.relatedOrder })
            && !loadingTypes && !submitting
    }

    func loadTypes(using account: TicketListViewModel, language: String) async {
        guard let token = account.currentToken() else { error = APIError.missingSession.localizedDescription; return }
        let scope = account.sessionScope, generation = UUID()
        typesGeneration = generation
        loadingTypes = true; error = nil
        defer { if typesGeneration == generation { loadingTypes = false } }
        do {
            let result: [SupportTicketType] = try await account.client.data(
                from: SupportTicketEndpoints.types(token: token), language: language)
            try account.checkSession(token, scope: scope)
            guard typesGeneration == generation else { return }
            types = result
            if !types.contains(where: { String($0.id) == form.category }) { form.category = "" }
        } catch {
            guard typesGeneration == generation, account.sessionScope == scope, account.currentToken() == token, !Task.isCancelled else { return }
            self.error = error.localizedDescription
        }
    }
    func loadOrders(using account: TicketListViewModel, language: String) async {
        guard let token = account.currentToken() else { ordersError = APIError.missingSession.localizedDescription; return }
        let scope = account.sessionScope, generation = UUID()
        ordersGeneration = generation
        loadingOrders = true; ordersError = nil
        defer { if ordersGeneration == generation { loadingOrders = false } }
        do {
            let result: [TicketOrderOption] = try await account.client.data(
                from: SupportTicketEndpoints.orders(token: token), language: language)
            try account.checkSession(token, scope: scope)
            guard ordersGeneration == generation else { return }
            orders = result
            if !orders.contains(where: { String($0.id) == form.relatedOrder }) { form.relatedOrder = "" }
        } catch {
            guard ordersGeneration == generation, account.sessionScope == scope,
                  account.currentToken() == token, !Task.isCancelled else { return }
            ordersError = error.localizedDescription
        }
    }
    func submit(using account: TicketListViewModel, language: String) async {
        guard canSubmit, createdTicket == nil, let submission = form.submission else { return }
        guard let token = account.currentToken() else { error = APIError.missingSession.localizedDescription; return }
        let scope = account.sessionScope
        submitting = true; error = nil
        defer { submitting = false }
        do {
            let ticket: AccountTicket = try await account.client.data(
                from: try SupportTicketEndpoints.create(submission, token: token), language: language)
            try account.checkSession(token, scope: scope)
            createdTicket = ticket
        } catch {
            guard account.sessionScope == scope, account.currentToken() == token, !Task.isCancelled else { return }
            self.error = error.localizedDescription
        }
    }
}
