import Foundation

enum HomeOfferFeed: String, Hashable {
    case search = "search-offers", nearby = "home/near-you", endingSoon = "home/ending-soon"
}

struct HomeEndpoints {
    private init() {}
}

extension HomeEndpoints {
    static
    func home(cityID: Int?, categoryID: Int?, token: String?) -> Endpoint<APIEnvelope<HomePageData>> {
        var query: APIParameters = [:]
        if let cityID { query["city_id"] = cityID }
        if let categoryID { query["category_id"] = categoryID }
        return Endpoint(
            path: "home-page",
            queries: query,
            headerType: .ifAuthourized(token: token)
        )
    }

    static
    func searchPage(token: String?) -> Endpoint<APIEnvelope<HomeSearchPageData>> {
        Endpoint(path: "search-page", headerType: .ifAuthourized(token: token))
    }

    static
    func categories(page: Int, token: String?) -> Endpoint<APIEnvelope<HomeCategoryPage>> {
        return Endpoint(
            path: "home/categories",
            queries: ["page": page],
            headerType: .ifAuthourized(token: token)
        )
    }
    static
    func filters(token: String?) -> Endpoint<APIEnvelope<[HomeFilterGroup]>> {
        return Endpoint(
            path: "static-filter",
            headerType: .ifAuthourized(token: token)
        )
    }
    static
    func offers(feed: HomeOfferFeed, query: APIParameters, token: String?) -> Endpoint<APIEnvelope<HomeOfferPage>> {
        return Endpoint(
            path: feed.rawValue,
            queries: query,
            headerType: .ifAuthourized(token: token)
        )
    }
    static
    func coupon(id: Int, token: String?) -> Endpoint<APIEnvelope<HomeOffer>> {
        return Endpoint(
            path: "coupon/\(id)",
            headerType: .ifAuthourized(token: token)
        )
    }
    static
    func cities(token: String?) -> Endpoint<APIEnvelope<[AuthOption]>> {
        return Endpoint(
            path: "cities",
            headerType: .ifAuthourized(token: token)
        )
    }
    static
    func favorites(page: Int, token: String) -> Endpoint<APIEnvelope<HomeOfferPage>> {
        return Endpoint(
            path: "favorites",
            queries: ["page": page],
            headerType: .authorized(token: token)
        )
    }
    static
    func toggleFavorite(id: Int, token: String) -> Endpoint<APIEnvelope<HomeFavoriteResult>> {
        return Endpoint(
            method: .post,
            path: "coupon/\(id)/toggle-favorite",
            headerType: .authorized(token: token)
        )
    }
}
