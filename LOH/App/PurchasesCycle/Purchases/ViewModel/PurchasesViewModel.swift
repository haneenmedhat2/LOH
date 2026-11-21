import Foundation
import Combine

@MainActor
final class PurchasesViewModel: ObservableObject {
    @Published private(set) var rows: [PurchaseListRow] = []
    @Published private(set) var filter: PurchaseFilter = .all
    @Published private(set) var totals: [PurchaseFilter: Int] = [:]
    @Published private(set) var loading = false
    @Published private(set) var loadingMore = false
    @Published private(set) var hasLoaded = false
    @Published private(set) var hasMore = false
    @Published private(set) var error: String?
    let client: DefaultResponseHandler
    var requiresSignIn: Bool { UserDefaults.accessToken == nil }
    private var requestID = UUID()
    private var nextPage = 1
    private var needsReload = true
    private var language = ""
    private var loadedToken: String?

    init(client: DefaultResponseHandler = DefaultResponseHandler()) {
        self.client = client
    }

    func reload(filter: PurchaseFilter, language: String) async {
        guard !Task.isCancelled else { return }
        guard let token = UserDefaults.accessToken else { reset(); return }
        if loadedToken != token || self.language != language { totals = [:] }
        if self.filter != filter || loadedToken != token || self.language != language {
            rows = []; hasLoaded = false
        }
        self.filter = filter; self.language = language; loadedToken = token
        nextPage = 1; needsReload = true; hasMore = false
        await fetch(page: 1, token: token)
    }

    func loadMore() async {
        guard hasMore, !needsReload, !loading, !loadingMore, !Task.isCancelled,
              let token = UserDefaults.accessToken, token == loadedToken else { return }
        await fetch(page: nextPage, token: token)
    }

    func retry(language: String) async {
        if needsReload { await reload(filter: filter, language: language) }
        else { await loadMore() }
    }

    private func fetch(page: Int, token: String) async {
        let request = UUID(), filter = filter, language = language
        requestID = request; error = nil
        loading = page == 1; loadingMore = page > 1
        defer {
            if requestID == request { loading = false; loadingMore = false }
        }
        do {
            let result: PurchasePage = try await client.data(
                from: PurchaseEndpoints.list(status: filter.status, page: page, token: token), language: language)
            try Task.checkCancellation()
            guard requestID == request, UserDefaults.accessToken == token else { return }
            if let pagination = result.pagination, pagination.currentPage != page { throw APIError.invalidResponse }
            let additions = result.coupons.enumerated().map {
                PurchaseListRow(id: "\(filter.rawValue):\(page):\($0.offset):\($0.element.id)", coupon: $0.element)
            }
            if page == 1 { rows = additions } else { rows.append(contentsOf: additions) }
            if let counts = result.counts {
                totals = counts.totals
            } else if let pagination = result.pagination {
                totals[filter] = pagination.totalItems
            }
            nextPage = page + 1
            hasMore = !additions.isEmpty && page < (result.pagination?.totalPages ?? page)
            hasLoaded = true; needsReload = false
        } catch {
            if requestID == request, UserDefaults.accessToken == token, !Task.isCancelled { self.error = error.localizedDescription }
        }
    }

    func reset() {
        requestID = UUID(); rows = []; totals = [:]; filter = .all
        loading = false; loadingMore = false; hasLoaded = false; hasMore = false
        error = nil; nextPage = 1; needsReload = true; language = ""; loadedToken = nil
    }
}
