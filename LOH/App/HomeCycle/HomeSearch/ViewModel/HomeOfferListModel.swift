import Foundation
import Combine

/// Each search screen owns its results, so overlapping navigation cannot overwrite them.
@MainActor final class HomeOfferListModel: ObservableObject {
    @Published private(set) var offers: [HomeOffer] = []
    @Published private(set) var loading = false
    @Published private(set) var hasLoaded = false
    @Published private(set) var error: String?
    @Published private(set) var hasMore = false
    @Published private(set) var total = 0
    @Published private(set) var cityName: String?
    private let client: DefaultResponseHandler
    private var generation = UUID()
    private var page = 0
    private var request: HomeSearchRequest?
    private var language = ""
    private var token: String?

    init(client: DefaultResponseHandler = DefaultResponseHandler()) { self.client = client }

    /// A changed query/filter/language must show placeholders during the debounce too.
    func matches(_ request: HomeSearchRequest, language: String) -> Bool {
        self.request == request && self.language == language
    }

    func reload(_ request: HomeSearchRequest, language: String, token: String?) async {
        generation = UUID()
        self.request = request
        self.language = language
        self.token = token
        hasLoaded = false
        offers = []
        page = 0
        total = 0
        cityName = nil
        hasMore = false
        loading = false
        await fetch()
    }
    func loadMore() async {
        guard hasMore, !loading else { return }
        await fetch()
    }
    func retry() async {
        guard !loading else { return }
        await fetch()
    }
    private func fetch() async {
        guard let request else { return }
        let generation = generation
        let nextPage = page + 1
        loading = true
        error = nil
        defer { if self.generation == generation { loading = false } }
        do {
            let data: HomeOfferPage = try await client.data(
                from: HomeEndpoints.offers(feed: request.feed, query: request.queryParameters(page: nextPage), token: token),
                language: language)
            try Task.checkCancellation()
            guard self.generation == generation else { return }
            let existing = Set(offers.map(\.id))
            var seen = existing
            let fresh = data.coupons.filter { seen.insert($0.id).inserted }
            offers += fresh
            hasLoaded = true
            page = nextPage
            total = data.total ?? data.pagination?.total ?? offers.count
            cityName = data.cityName
            hasMore =
                !fresh.isEmpty && (data.pagination.map { $0.current == nextPage && $0.current < $0.pages } ?? false)
        } catch {
            if self.generation == generation && !Task.isCancelled { self.error = error.localizedDescription }
        }
    }
}
