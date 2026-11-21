import Foundation

@MainActor enum HomeServiceTests {
    static func fixture(_ name: String) throws -> String {
        let directory = URL(fileURLWithPath: #filePath).deletingLastPathComponent().appendingPathComponent("Fixtures")
        return try String(contentsOf: directory.appendingPathComponent(name + ".json"), encoding: .utf8)
    }
    static func testFavorites(client: APIClient) async throws {
        let service = LOHHomeFavoritesService(client: client)
        let response = #"{"key":"success","data":{"pagination":{"total_items":1,"total_pages":1,"current_page":1},"coupons":[{"id":197,"image":"https://example.com/offer.png","is_favorite":true,"distance":null,"is_available":true,"store_name":"TestLoh","store_image":"https://example.com/store.png","coupon_name":"Test Offer","price":1,"original_price":1,"currency":"ريال","discount":null}]}}"#
        MockProtocol.handler = { request in
            precondition(request.httpMethod == "GET" && request.url!.path == "/api/favorites")
            precondition(request.value(forHTTPHeaderField: "Authorization") == "Bearer favorites-token")
            precondition(request.value(forHTTPHeaderField: "lang") == "en")
            return (200, response)
        }
        let model = HomeViewModel(favoritesService: service, currentToken: { "favorites-token" })
        await model.loadFavorites(language: "en")
        precondition(model.favoritesLoaded && model.favoritesLoadError == nil && model.savedOffers.count == 1)
        precondition(model.favorites == ["197"] && !model.savedOffers[0].hasDistance)
        precondition(model.savedOffers[0].discount == 0 && model.savedOffers[0].merchantImage != nil)
        MockProtocol.handler = { request in
            precondition(request.httpMethod == "POST" && request.url!.path == "/api/coupon/197/toggle-favorite")
            precondition(request.value(forHTTPHeaderField: "Authorization") == "Bearer favorites-token")
            precondition(request.httpBody == nil && request.url!.query == nil)
            return (200, #"{"key":"success","data":{"id":197,"is_favorite":false}}"#)
        }
        await model.updateFavorite("197", language: "en")
        precondition(model.favorites.isEmpty && model.savedOffers.isEmpty && model.updatingFavorites.isEmpty)
        precondition(model.favoriteNotice?.isFavorite == false)
        let removedNoticeID = model.favoriteNotice!.id
        MockProtocol.handler = { _ in (200, #"{"key":"success","data":{"id":197,"is_favorite":true}}"#) }
        await model.updateFavorite("197", language: "en")
        precondition(model.favorites.contains("197") && model.savedOffers.count == 1)
        precondition(model.favoriteNotice?.isFavorite == true)
        model.dismissFavoriteNotice(id: removedNoticeID)
        precondition(model.favoriteNotice != nil, "An older timer must not dismiss a new confirmation")
        model.dismissFavoriteNotice(id: model.favoriteNotice!.id)
        precondition(model.favoriteNotice == nil)
        MockProtocol.handler = { _ in (500, #"{"key":"fail","msg":"Try again"}"#) }
        await model.updateFavorite("197", language: "en")
        precondition(model.favorites.contains("197") && model.savedOffers.count == 1 && model.favoriteError == "Try again")
        precondition(model.favoriteNotice == nil, "Failures must not show a success message")
        let guest = HomeViewModel(favoritesService: service, currentToken: { nil })
        await guest.updateFavorite("197", language: "en")
        precondition(guest.showsFavoritesLogin && guest.favorites.isEmpty)
        await guest.loadFavorites(language: "en")
        precondition(!guest.favoritesLoaded && guest.favoritesLoadError != nil)
        // Every page is fetched; duplicate coupon IDs appear once.
        MockProtocol.handler = { request in
            let page = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)!.queryItems!.first!.value!
            return (200, "{\"key\":\"success\",\"data\":{\"pagination\":{\"total_items\":2,\"total_pages\":2,\"current_page\":\(page)},\"coupons\":[{\"id\":197,\"price\":1},{\"id\":\(page == "1" ? "197" : "198"),\"price\":2}]}}")
        }
        let all = try await service.favorites(token: "favorites-token", language: "en")
        precondition(all.map(\.id) == ["197", "198"])
    }
    static func run(client: APIClient) async throws {
        let service = LOHHomeService(client: client)
        let home = try fixture("home-page")
        MockProtocol.handler = { request in
            precondition(request.url!.path == "/api/home-page")
            let query = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)!.queryItems!
            precondition(query.contains(.init(name: "city_id", value: "37")))
            precondition(query.contains(.init(name: "category_id", value: "91")))
            precondition(request.value(forHTTPHeaderField: "Authorization") == "Bearer test-session")
            precondition(request.value(forHTTPHeaderField: "lang") == "ar")
            return (200, home)
        }
        let page = try await service.home(cityID: 37, categoryID: 91, token: "test-session", language: "ar")
        precondition(page.city?.id == 21 && page.nearby.isEmpty && page.endingSoon.isEmpty)
        precondition(page.banners.first?.couponID == 98 && page.banners.first?.image?.hasPrefix("https:") == true)

        // Supplied live response: ending_soon summaries have no name and a nullable discount.
        let populatedHome = try fixture("home-page-riyadh")
        MockProtocol.handler = { request in
            precondition(request.url!.path == "/api/home-page")
            precondition(URLComponents(url: request.url!, resolvingAgainstBaseURL: false)!.queryItems == [.init(name: "city_id", value: "1")])
            precondition(request.value(forHTTPHeaderField: "lang") == "ar")
            return (200, populatedHome)
        }
        let startedAt = Date()
        let riyadh = try await service.home(cityID: 1, categoryID: nil, token: "test-session", language: "ar")
        let finishedAt = Date()
        precondition(riyadh.city?.id == 1 && riyadh.city?.name == "الرياض")
        precondition(riyadh.categories.count == 17 && riyadh.nearby.isEmpty && riyadh.endingSoon.count == 1)
        precondition(riyadh.user?.name == "test userr" && riyadh.user?.greeting == "مساء الخير، test userr")
        precondition(riyadh.user?.greetingSubtitle == "وش ودك توفر عليه اليوم؟" && riyadh.user?.image?.hasSuffix("users/default.png") == true)
        precondition(riyadh.cartCount == 0 && riyadh.notificationsCount == 0 && riyadh.showAd == true)
        precondition(riyadh.cashback?.image == nil && riyadh.cashback?.button == "اعرف أكثر")
        precondition(riyadh.banners.count == 3 && riyadh.banners[0].title == nil)
        precondition(riyadh.banners[0].type == "inside" && riyadh.banners[0].couponName == "فطور رقشة")
        precondition(riyadh.banners[0].startAt == "2026-10-15" && riyadh.banners[0].endAt == "2026-10-20")
        precondition(riyadh.banners[0].iosImage == riyadh.banners[0].image && riyadh.banners[0].androidImage != nil)
        precondition(riyadh.banners[1].type == "outside" && riyadh.banners[1].couponID == nil && riyadh.banners[1].link == "https://www.google.com/")
        let summary = riyadh.endingSoon[0]
        precondition(summary.id == "196" && summary.title.isEmpty && summary.merchant == "top store test")
        precondition(summary.categoryName == "مطاعم" && summary.currency == "ريال" && summary.isFavorite == false)
        precondition(summary.price == 10 && summary.originalPrice == 10 && summary.discount == 0)
        precondition(summary.endsIn == "211979:12:04" && summary.endsInSeconds == 763125124)
        precondition(summary.expiresAt! >= startedAt.addingTimeInterval(763125124) && summary.expiresAt! <= finishedAt.addingTimeInterval(763125124))
        precondition(!summary.hasDistance && !summary.hasRating && !summary.available)

        let decoder = JSONDecoder()
        let nullable = try decoder.decode(HomeOffer.self, from: Data(#"{"id":"197","name":null,"price":"10","discount":null,"ends_in_seconds":null,"is_favorite":null}"#.utf8))
        precondition(nullable.title.isEmpty && nullable.discount == 0 && nullable.expiresAt == nil && nullable.isFavorite == nil)
        let compact = try decoder.decode(HomeOffer.self, from: Data(#"{"id":198,"price":10,"discount":"25","ends_in_seconds":"60","is_favorite":"1"}"#.utf8))
        precondition(compact.discount == 25 && compact.endsInSeconds == 60 && compact.isFavorite == true && compact.expiresAt != nil)
        let absolute = try decoder.decode(HomeOffer.self, from: Data(#"{"id":199,"price":10,"ends_in_seconds":60,"time_appearance_finish_at_date_time":2000000000}"#.utf8))
        precondition(absolute.expiresAt == Date(timeIntervalSince1970: 2000000000))
        for invalid in [#"{"price":10}"#, #"{"id":196}"#, #"{"id":196,"price":-1}"#] {
            do { _ = try decoder.decode(HomeOffer.self, from: Data(invalid.utf8)); preconditionFailure("IDs and valid prices remain required") }
            catch { }
        }

        let populatedModel = HomeViewModel(service: service, favoritesService: LOHHomeFavoritesService(client: client), currentToken: { "test-session" })
        MockProtocol.handler = { _ in (200, populatedHome) }
        await populatedModel.load(language: "ar")
        precondition(populatedModel.error == nil && !populatedModel.loading && populatedModel.endingSoon.first?.id == "196")
        precondition(populatedModel.user?.greeting == riyadh.user?.greeting && populatedModel.showAd == true && populatedModel.cartCount == 0)
        populatedModel.cache([compact])
        precondition(populatedModel.favorites.contains(compact.id))
        MockProtocol.handler = { request in
            precondition(request.url!.path == "/api/coupon/198/toggle-favorite" && request.httpMethod == "POST")
            precondition(request.value(forHTTPHeaderField: "Authorization") == "Bearer test-session")
            return (200, #"{"key":"success","data":{"id":198,"is_favorite":false}}"#)
        }
        await populatedModel.updateFavorite(compact.id, language: "ar")
        populatedModel.cache([compact])
        precondition(!populatedModel.favorites.contains(compact.id), "Refresh must preserve the confirmed favorite change")
        populatedModel.resetSession()
        precondition(populatedModel.user == nil && populatedModel.cartCount == 0 && populatedModel.showAd == nil && populatedModel.endingSoon.isEmpty)
        populatedModel.cache([compact])
        precondition(populatedModel.favorites.contains(compact.id), "Session reset must clear favorite overrides")
        MockProtocol.handler = { _ in (200, #"{"key":"success","data":{"cart_count":"3","notifications_count":"2","show_ad":"0"}}"#) }
        await populatedModel.load(language: "en")
        precondition(populatedModel.error == nil && populatedModel.user == nil && populatedModel.cashback == nil && populatedModel.banners.isEmpty)
        precondition(populatedModel.cartCount == 3 && populatedModel.notificationsCount == 2 && populatedModel.showAd == false)

        try await testFavorites(client: client)

        let categories = try fixture("home-categories")
        MockProtocol.handler = { _ in (200, categories) }
        let options = try await service.categories(language: "en", token: nil)
        precondition(options.first?.id == 17 && options.count == 17)
        let filters = try fixture("static-filter")
        MockProtocol.handler = { request in
            precondition(request.httpMethod == "GET" && request.url!.path == "/api/static-filter")
            precondition(request.url!.query == nil && request.httpBody == nil)
            precondition(request.value(forHTTPHeaderField: "lang") == "en")
            precondition(request.value(forHTTPHeaderField: "Authorization") == nil)
            return (200, filters)
        }
        let groups = try await service.filters(language: "en", token: nil)
        precondition(groups.first?.options.first?.maximum == 20)
        precondition(groups.last?.options.first?.minimum == 3.5)

        var criteria = HomeSearchRequest(query: "قهوة & cake", cityID: 37, categoryID: 91)
        criteria.filters.minimumPrice = 20.5
        criteria.filters.maximumPrice = 1200
        criteria.filters.distance = 5
        criteria.filters.discount = 30
        criteria.filters.discountOptionID = groups.first { $0.type == "discount" }!.options[1].id
        criteria.filters.availableOnly = true
        criteria.filters.endingToday = true
        criteria.filters.rating = 4.5
        criteria.filters.ratingOptionID = groups.first { $0.type == "rating" }!.options[2].id
        criteria.sort = .price
        let empty = try fixture("search-empty")
        MockProtocol.handler = { request in
            precondition(request.url!.path == "/api/search-offers" && request.httpMethod == "GET")
            precondition(request.httpBody == nil && request.value(forHTTPHeaderField: "lang") == "ar")
            precondition(request.value(forHTTPHeaderField: "Authorization") == nil)
            let items = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)!.queryItems!
            let query = Dictionary(uniqueKeysWithValues: items.map { ($0.name, $0.value!) })
            precondition(query["name"] == "قهوة & cake" && query["category_id"] == "91" && query["city_id"] == "37")
            precondition(query["min_price"] == "20.5" && query["max_price"] == "1200.0")
            precondition(query["min_distance"] == "0" && query["max_distance"] == "5.0")
            precondition(query["rate"] == "10" && query["discount"] == "5")
            precondition(query["static_price"] == nil)
            precondition(query["available_now"] == "1" && query["ending_today"] == "1")
            precondition(query["sort"] == "price_low" && query["page"] == "2")
            return (200, empty)
        }
        let result = try await service.offers(criteria, page: 2, token: nil, language: "ar")
        precondition(result.coupons.isEmpty && result.pagination?.total == 0)
        precondition(result.total == 0 && result.cityName == nil)
        let defaults = HomeSearchRequest().queryParameters(page: 1)
        precondition(defaults["sort"] == nil && defaults["page"] as? Int == 1)
        precondition(["min_price", "max_price", "min_distance", "max_distance", "category_id", "static_price", "discount", "rate"].allSatisfy { defaults[$0] == nil })
        for distance in [1.0, 8.0] {
            var request = HomeSearchRequest()
            request.filters.distance = distance
            let query = request.queryParameters(page: 1)
            precondition(query["min_distance"] as? String == "0")
            precondition(query["max_distance"] as? String == String(distance))
        }
        var nearest = HomeSearchRequest()
        nearest.sort = .nearest
        precondition(nearest.queryParameters(page: 1)["sort"] as? String == "nearest")
        nearest.sort = .price
        precondition(nearest.queryParameters(page: 1)["sort"] as? String == "price_low")
        nearest.sort = nil
        precondition(nearest.queryParameters(page: 1)["sort"] == nil)

        // The backend rejects raw thresholds (discount=20, rate=4.5); presets use server IDs.
        var preset = HomeSearchRequest(categoryID: 91)
        preset.filters.categoryID = 42
        preset.filters.staticPriceID = groups.first { $0.type == "price" }!.options[0].id
        preset.filters.minimumPrice = 0; preset.filters.maximumPrice = 20
        preset.filters.discountOptionID = groups.first { $0.type == "discount" }!.options[0].id
        preset.filters.ratingOptionID = groups.first { $0.type == "rating" }!.options[0].id
        MockProtocol.handler = { request in
            let items = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)!.queryItems!
            let query = Dictionary(uniqueKeysWithValues: items.map { ($0.name, $0.value!) })
            precondition(query["static_price"] == "1" && query["discount"] == "4" && query["rate"] == "8")
            precondition(query["min_price"] == nil && query["max_price"] == nil && query["category_id"] == "42")
            precondition(request.value(forHTTPHeaderField: "Authorization") == "Bearer test-session")
            return (200, empty)
        }
        _ = try await service.offers(preset, page: 1, token: "test-session", language: "en")
        precondition(preset.filters.count == 4)
        preset.filters.staticPriceID = nil
        let manualPrice = preset.queryItems(page: 1)
        precondition(!manualPrice.contains { $0.name == "static_price" })
        precondition(manualPrice.contains(.init(name: "max_price", value: "20.0")))
        var highPrice = OfferFilters(); highPrice.maximumPrice = 1200
        precondition(highPrice.count == 1)

        let coupon = #"{"id":"91","name":"Real offer","price":"110.75","original_price":"220.50","store_name":"Merchant","category_id":"42","category_name":"Category","image":"https://example.invalid/image.jpg","description":"Full description","available":true,"time_appearance_finish_at_date_time":2000000000}"#
        let searchList = HomeOfferListModel(service: service)
        precondition(!searchList.hasLoaded, "Do not show an empty state before the first search")
        MockProtocol.handler = { _ in
            (200, "{\"key\":\"success\",\"data\":{\"coupons\":[\(coupon)],\"total\":\"12\",\"city_name\":\"Riyadh\"}}")
        }
        await searchList.reload(HomeSearchRequest(query: "coffee"), language: "en", token: nil)
        precondition(searchList.hasLoaded)
        precondition(searchList.total == 12 && searchList.cityName == "Riyadh" && searchList.offers.count == 1)
        precondition(!searchList.hasMore && searchList.error == nil)
        MockProtocol.handler = { _ in (200, #"{"key":"fail","msg":"The selected Discount percentage is invalid."}"#) }
        await searchList.reload(preset, language: "en", token: nil)
        precondition(searchList.error == "The selected Discount percentage is invalid.")
        precondition(searchList.cityName == nil && searchList.total == 0)
        MockProtocol.handler = { _ in (200, empty) }
        await searchList.retry()
        precondition(searchList.offers.isEmpty && searchList.total == 0 && searchList.error == nil && !searchList.loading)
        MockProtocol.handler = { request in
            precondition(request.url!.path == "/api/coupon/91")
            return (200, "{\"key\":\"success\",\"data\":\(coupon)}")
        }
        let offer = try await service.detail(id: "91", token: nil, language: "en")
        precondition(offer.price == 110.75 && offer.originalPrice == 220.50)
        precondition(offer.id == "91" && offer.categoryID == 42 && offer.available && offer.isRemote)
        precondition(!offer.hasDistance && !offer.hasRating && offer.descriptionText == "Full description")
        precondition(offer.expiresAt == Date(timeIntervalSince1970: 2000000000))
        MockProtocol.handler = { _ in (200, #"{"key":"fail","msg":"This offer is currently unavailable"}"#) }
        do { _ = try await service.detail(id: "91", token: nil, language: "en"); preconditionFailure("Unavailable offers must fail") }
        catch { precondition(error.localizedDescription == "This offer is currently unavailable") }

        var calls = 0
        MockProtocol.handler = { request in
            precondition(request.url!.path == "/api/home/near-you")
            calls += 1
            let page = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)!.queryItems!.first { $0.name == "page" }!.value!
            if calls == 2 { return (503, #"{"key":"exception","msg":"Retry"}"#) }
            return (200, "{\"key\":\"success\",\"data\":{\"coupons\":[\(coupon)],\"pagination\":{\"current_page\":\(page),\"total_pages\":3,\"total_items\":2}}}")
        }
        let list = HomeOfferListModel(service: service)
        await list.reload(HomeSearchRequest(feed: .nearby), language: "en", token: nil)
        precondition(list.offers.count == 1 && list.hasMore)
        await list.loadMore()
        precondition(list.offers.count == 1 && list.error != nil && list.hasMore)
        await list.retry()
        precondition(list.offers.count == 1 && !list.hasMore && list.error == nil)
        // Both failed and successful retries use the same next page; duplicates cannot cause an infinite pager.
        precondition(calls == 3)

        let stalePage = HomeOfferPage(coupons: [offer], pagination: nil)
        let emptyPage = HomeOfferPage(coupons: [], pagination: nil)
        let delayed = HomeOfferListModel(service: DelayedHomeService(base: service, old: stalePage, new: emptyPage))
        let slow = Task { await delayed.reload(HomeSearchRequest(query: "old"), language: "en", token: nil) }
        try await Task.sleep(nanoseconds: 10_000_000)
        await delayed.reload(HomeSearchRequest(query: "new"), language: "ar", token: nil)
        await slow.value
        precondition(delayed.offers.isEmpty && !delayed.loading && delayed.error == nil)

        let model = HomeViewModel(service: service)
        precondition(model.offers.isEmpty)
        MockProtocol.handler = { request in
            switch request.url!.lastPathComponent {
            case "home-page": return (200, #"{"key":"success","data":{"categories":[{"id":301,"name":"Home category","image":null}]}}"#)
            case "categories": return (200, categories)
            case "static-filter": return (200, filters)
            default: preconditionFailure("Unexpected options request")
            }
        }
        await model.load(language: "en")
        let homeCategories = model.categories
        try await model.loadFilterOptions(language: "en")
        precondition(model.categories == homeCategories, "Filter options must not replace home-page categories")
        precondition(model.filterCategories.count == 17 && model.filterGroups.count == 3)
        model.cache([offer, offer])
        precondition(model.offers.count == 1)
        model.remember(" Coffee "); model.remember("coffee")
        precondition(model.recentSearches.count == 1)
        model.resetSession()
        precondition(model.offers.isEmpty && model.favorites.isEmpty && model.recentSearches.isEmpty)
        precondition(model.filterCategories.isEmpty && model.filterGroups.isEmpty && model.filters.count == 0)
        print("PASS: Live home summary schema, optional metadata, countdowns, favorite state, static-filter IDs, search queries, category isolation, retry, pagination and stale search suppression")
    }
}

private struct DelayedHomeService: HomeServicing {
    let base: HomeServicing
    let old: HomeOfferPage
    let new: HomeOfferPage
    func offers(_ request: HomeSearchRequest, page: Int, token: String?, language: String) async throws -> HomeOfferPage {
        // Intentionally ignore cancellation: the model must also reject stale responses.
        try? await Task.sleep(nanoseconds: request.query == "old" ? 100_000_000 : 1_000_000)
        return request.query == "old" ? old : new
    }
    func home(cityID: Int?, categoryID: Int?, token: String?, language: String) async throws -> HomePageData {
        try await base.home(cityID: cityID, categoryID: categoryID, token: token, language: language)
    }
    func categories(language: String, token: String?) async throws -> [HomeAPICategory] { try await base.categories(language: language, token: token) }
    func filters(language: String, token: String?) async throws -> [HomeFilterGroup] { try await base.filters(language: language, token: token) }
    func detail(id: String, token: String?, language: String) async throws -> HomeOffer { try await base.detail(id: id, token: token, language: language) }
    func cities(language: String, token: String?) async throws -> [AuthOption] { try await base.cities(language: language, token: token) }
}
