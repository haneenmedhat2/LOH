import Foundation
import Combine

/// Live catalog state shared by Home, search and offer details.
@MainActor
final class HomeViewModel: ObservableObject {
    @Published var city: OfferCity = .tabuk
    @Published var filters = OfferFilters()
    @Published var favorites: Set<String> = []
    @Published var followedMerchants: Set<String> = []
    @Published var recentSearches: [String] = []
    @Published private(set) var hidesServerRecentSearches = false
    @Published private(set) var hiddenServerRecentKeywords = Set<String>()
    @Published private(set) var offers: [HomeOffer] = []
    @Published private(set) var nearby: [HomeOffer] = []
    @Published private(set) var endingSoon: [HomeOffer] = []
    @Published private(set) var categories: [HomeAPICategory] = []
    @Published private(set) var banners: [HomeBanner] = []
    @Published private(set) var filterGroups: [HomeFilterGroup] = []
    @Published private(set) var filterCategories: [HomeAPICategory] = []
    @Published private(set) var cashback: HomeCashback?
    @Published private(set) var user: HomeUser?
    @Published private(set) var cityName = ""
    @Published private(set) var selectedCityID: Int?
    @Published private(set) var notificationsCount = 0
    @Published private(set) var cartCount = 0
    @Published private(set) var showAd: Bool?
    @Published private(set) var loading = false
    @Published private(set) var hasLoaded = false
    @Published private(set) var error: String?
    let client: DefaultResponseHandler
    private var generation = UUID()
    private var filterGeneration = UUID()
    private var homeContext = ""
    @Published private(set) var savedOffers: [HomeOffer] = []
    @Published private(set) var favoritesLoading = false
    @Published private(set) var favoritesLoaded = false
    @Published private(set) var favoritesLoadError: String?
    @Published private(set) var updatingFavorites = Set<String>()
    struct FavoriteNotice: Identifiable {
        let id = UUID()
        let isFavorite: Bool
    }
    @Published private(set) var favoriteNotice: FavoriteNotice?
    @Published var favoriteError: String?
    @Published var showsFavoritesLogin = false
    private let currentToken: @MainActor () -> String?
    private var favoritesGeneration = UUID()
    private var favoriteRevision = 0
    private var favoriteSession = UUID()
    private var favoriteOverrides: [String: Bool] = [:]

    init(client: DefaultResponseHandler = DefaultResponseHandler(),
         currentToken: @escaping @MainActor () -> String? = { UserDefaults.accessToken }) {
        self.client = client
        self.currentToken = currentToken
    }
    var resolvedCityID: Int? { selectedCityID ?? UserDefaults.apiUser?.cities.first?.id }
    var displayedCityName: String { cityName.isEmpty ? (UserDefaults.apiUser?.cities.first?.name ?? NSLocalizedString("home.chooseCity", comment: "")) : cityName }

    func load(language: String, categoryID: Int? = nil) async {
        let generation = UUID()
        self.generation = generation
        let token = UserDefaults.accessToken
        let context = "\(language):\(resolvedCityID ?? -1):\(categoryID ?? -1)"
        if context != homeContext {
            hasLoaded = false
            nearby = []; endingSoon = []; banners = []; cashback = nil
            user = nil; cartCount = 0; showAd = nil
            homeContext = context
        }
        loading = true; error = nil
        defer { if self.generation == generation { loading = false } }
        do {
            let page: HomePageData = try await client.data(
                from: HomeEndpoints.home(cityID: resolvedCityID, categoryID: categoryID, token: token),
                language: language)
            try Task.checkCancellation()
            guard self.generation == generation, UserDefaults.accessToken == token else { return }
            nearby = unique(page.nearby); endingSoon = unique(page.endingSoon)
            categories = page.categories; banners = page.banners
            cityName = page.city?.name ?? UserDefaults.apiUser?.cities.first?.name ?? ""
            notificationsCount = page.notificationsCount; cashback = page.cashback
            user = page.user; cartCount = page.cartCount; showAd = page.showAd
            cache(page.nearby + page.endingSoon)
            hasLoaded = true
        } catch {
            if self.generation == generation && !Task.isCancelled {
                self.error = error.localizedDescription
            }
        }
    }
    func loadFilterOptions(language: String) async throws {
        let generation = UUID()
        filterGeneration = generation
        let token = UserDefaults.accessToken
        async let categories = loadCategories(language: language, token: token)
        async let groups: [HomeFilterGroup] = client.data(
            from: HomeEndpoints.filters(token: token), language: language)
        let result = try await (categories, groups)
        try Task.checkCancellation()
        guard filterGeneration == generation, UserDefaults.accessToken == token else { throw CancellationError() }
        filterCategories = result.0; filterGroups = result.1
    }
    private func loadCategories(language: String, token: String?) async throws -> [HomeAPICategory] {
        var values: [HomeAPICategory] = []
        var seen = Set<Int>()
        var page = 1
        while true {
            let result: HomeCategoryPage = try await client.data(
                from: HomeEndpoints.categories(page: page, token: token), language: language)
            values += result.categories.filter { seen.insert($0.id).inserted }
            guard let pagination = result.pagination, pagination.current < pagination.pages else { return values }
            guard pagination.current == page else { throw APIError.invalidResponse }
            page += 1
        }
    }
    func selectCity(_ option: AuthOption) async throws {
        if UserDefaults.accessToken != nil {
            guard let token = UserDefaults.accessToken else { throw APIError.missingSession }
            try await DefaultResponseHandler().perform(
                AuthEndpoints.selectCity(id: option.id, token: token), language: AppLanguageManager.shared.apiLanguage)
            if var user = UserDefaults.apiUser {
                user.cities = [AuthOption(id: option.id, name: option.name, isSelected: true)]
                UserDefaults.save(user)
            }
        }
        generation = UUID()
        selectedCityID = option.id; cityName = option.name
        offers = []; nearby = []; endingSoon = []; banners = []
        cashback = nil; user = nil; cartCount = 0; showAd = nil
        hasLoaded = false; error = nil
    }
    func cache(_ items: [HomeOffer]) {
        for item in items {
            guard let favorite = favoriteOverrides[item.id] ?? item.isFavorite else { continue }
            if favorite { favorites.insert(item.id) } else { favorites.remove(item.id) }
        }
        let ids = Set(items.map(\.id))
        offers = unique(offers.filter { !ids.contains($0.id) } + items)
    }
    private func unique(_ items: [HomeOffer]) -> [HomeOffer] {
        var ids = Set<String>()
        return items.filter { ids.insert($0.id).inserted }
    }

    func results(query: String = "", category: OfferCategory = .all, sort: OfferSort = .nearest) -> [HomeOffer] {
        OfferSearch.results(in: offers, query: query, category: category, filters: filters, sort: sort)
    }
    var favoritesNeedLogin: Bool { currentToken()?.isEmpty != false }

    func loadFavorites(language: String) async {
        let generation = UUID()
        favoritesGeneration = generation
        let revision = favoriteRevision
        guard let token = currentToken(), !token.isEmpty else {
            savedOffers = []; favoritesLoaded = false; favoritesLoading = false
            favoritesLoadError = APIError.missingSession.localizedDescription
            return
        }
        favoritesLoading = true; favoritesLoadError = nil
        defer { if favoritesGeneration == generation { favoritesLoading = false } }
        do {
            let items = try await fetchFavorites(token: token, language: language)
            try Task.checkCancellation()
            guard favoritesGeneration == generation, currentToken() == token else { return }
            // A mutation completed while this list was loading. Fetch the updated server list.
            guard favoriteRevision == revision else {
                await loadFavorites(language: language)
                return
            }
            favoriteOverrides = [:]
            favorites = Set(items.map(\.id))
            savedOffers = unique(items)
            cache(items)
            favoritesLoaded = true
        } catch {
            guard favoritesGeneration == generation, currentToken() == token, !Task.isCancelled else { return }
            favoritesLoadError = error.localizedDescription
        }
    }

    private func fetchFavorites(token: String, language: String) async throws -> [HomeOffer] {
        var offers: [HomeOffer] = []
        var seen = Set<String>()
        var page = 1
        while true {
            let result: HomeOfferPage = try await client.data(
                from: HomeEndpoints.favorites(page: page, token: token), language: language)
            offers += result.coupons.filter { seen.insert($0.id).inserted }
            guard let pagination = result.pagination else { return offers }
            guard pagination.current == page else { throw APIError.invalidResponse }
            guard page < pagination.pages else { return offers }
            guard !result.coupons.isEmpty else { throw APIError.invalidResponse }
            page += 1
        }
    }

    @discardableResult
    func toggleFavorite(_ id: String, language: String = "ar") -> Task<Void, Never> {
        let session = favoriteSession
        return Task {
            guard favoriteSession == session else { return }
            await updateFavorite(id, language: language)
        }
    }

    func updateFavorite(_ id: String, language: String) async {
        guard !updatingFavorites.contains(id) else { return }
        guard let token = currentToken(), !token.isEmpty else {
            showsFavoritesLogin = true
            return
        }
        let session = favoriteSession
        updatingFavorites.insert(id)
        favoriteError = nil
        favoriteNotice = nil
        defer { if favoriteSession == session, currentToken() == token { updatingFavorites.remove(id) } }
        do {
            guard let numericID = Int(id), numericID > 0 else { throw APIError.invalidResponse }
            let result: HomeFavoriteResult = try await client.data(
                from: HomeEndpoints.toggleFavorite(id: numericID, token: token), language: language)
            guard result.id == numericID else { throw APIError.invalidResponse }
            let isFavorite = result.isFavorite
            guard favoriteSession == session, currentToken() == token else { return }
            favoriteRevision += 1
            favoriteOverrides[id] = isFavorite
            if isFavorite {
                favorites.insert(id)
                if !savedOffers.contains(where: { $0.id == id }), let offer = offers.first(where: { $0.id == id }) {
                    savedOffers.append(offer)
                }
            } else {
                favorites.remove(id)
                savedOffers.removeAll { $0.id == id }
            }
            favoriteNotice = FavoriteNotice(isFavorite: isFavorite)
        } catch {
            guard favoriteSession == session, currentToken() == token, !Task.isCancelled else { return }
            // Leave the confirmed favorite state intact when the request fails.
            favoriteNotice = nil
            favoriteError = error.localizedDescription
        }
    }
    func dismissFavoriteNotice(id: UUID) {
        guard favoriteNotice?.id == id else { return }
        favoriteNotice = nil
    }

    func toggleFollow(_ merchant: String) {
        if !followedMerchants.insert(merchant).inserted { followedMerchants.remove(merchant) }
    }
    func remember(_ query: String) {
        let value = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else { return }
        recentSearches.removeAll { $0.localizedCaseInsensitiveCompare(value) == .orderedSame }
        recentSearches.insert(value, at: 0)
        recentSearches = Array(recentSearches.prefix(6))
    }
    func clearRecentSearches() {
        recentSearches.removeAll()
        hidesServerRecentSearches = true
    }
    func removeRecentSearch(_ keyword: String) {
        let key = keyword.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        recentSearches.removeAll { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == key }
        hiddenServerRecentKeywords.insert(key)
    }
    func resetSession() {
        favoritesGeneration = UUID(); favoriteSession = UUID(); favoriteRevision += 1
        savedOffers = []; favoritesLoaded = false; favoritesLoading = false
        favoriteNotice = nil
        favoritesLoadError = nil; favoriteError = nil; updatingFavorites = []; showsFavoritesLogin = false
        favorites = []; followedMerchants = []
        favoriteOverrides = [:]
        filters = OfferFilters()
        generation = UUID()
        selectedCityID = nil; cityName = ""; homeContext = ""
        offers = []; nearby = []; endingSoon = []; categories = []; banners = []
        filterGeneration = UUID()
        filterGroups = []; filterCategories = []; cashback = nil; notificationsCount = 0
        user = nil; cartCount = 0; showAd = nil
        loading = false; hasLoaded = false; error = nil; recentSearches = []
        hidesServerRecentSearches = false
        hiddenServerRecentKeywords = []
    }
}
