import Foundation

@MainActor enum MerchantTests {
    static func run(client: APIClient) async throws {
        let fixture = try HomeServiceTests.fixture("store-78")
        let service = LOHMerchantService(client: client)
        MockProtocol.handler = { request in
            precondition(request.httpMethod == "GET" && request.url?.path == "/api/store/78")
            precondition(request.value(forHTTPHeaderField: "Authorization") == "Bearer merchant-session")
            precondition(request.value(forHTTPHeaderField: "lang") == "ar")
            precondition(URLComponents(url: request.url!, resolvingAgainstBaseURL: false)?.queryItems == [.init(name: "category_id", value: "1")])
            return (200, fixture)
        }
        let store = try await service.store(id: 78, categoryID: 1, token: "merchant-session", language: "ar")
        precondition(store.id == 78 && store.name == "TestLoh" && store.isVerified && !store.isFollowed)
        precondition(store.cover == nil && store.rating == nil && store.distance == nil)
        precondition(store.ratingCount == 0 && store.stats.offersCount == 1 && store.about == "")
        precondition(store.categories.map(\.id) == [17, 1])
        precondition(store.location?.address == "الرياض" && store.location?.url == nil)
        precondition(store.offers.count == 1 && store.offers[0].id == "197")
        precondition(store.offers[0].store?.id == 78 && store.offers[0].available && store.offers[0].title == "Test Offer")

        MockProtocol.handler = { request in
            precondition(request.httpMethod == "POST" && request.url?.path == "/api/store/78/toggle-follow")
            precondition(request.value(forHTTPHeaderField: "Authorization") == "Bearer merchant-session")
            precondition(request.httpBody == nil && request.url?.query == nil)
            return (200, #"{"key":"success","msg":"Done"}"#)
        }
        try await service.toggleFollow(id: 78, token: "merchant-session", language: "ar")
        MockProtocol.handler = { _ in (200, fixture) }
        do {
            _ = try await service.store(id: 79, categoryID: nil, token: nil, language: "en")
            preconditionFailure("Reject a response for a different store")
        } catch { }
        do {
            _ = try await service.store(id: 0, categoryID: nil, token: nil, language: "en")
            preconditionFailure("Never request a placeholder store ID")
        } catch { }

        let rich = #"{"id":"79","name":"Cafe","is_verified":"1","is_followed":"1","followers_count":"12","rating":"4.8","distance":"1.2 km","stats":{"offers_count":"3","distance":"1.2","rating":"4.8"},"location":{"lat":"24.7136","lng":"46.6753","address":"Riyadh"}}"#
        let decoded = try JSONDecoder().decode(HomeMerchant.self, from: Data(rich.utf8))
        precondition(decoded.isFollowed && decoded.followersCount == 12 && decoded.rating == 4.8)
        precondition(decoded.distance == .text("1.2 km") && decoded.stats.distance == .kilometers(1.2))
        precondition(decoded.location?.url?.host == "maps.apple.com")
        let unsafe = try JSONDecoder().decode(HomeMerchantLocation.self, from: Data(#"{"directions_url":"javascript:alert(1)","lat":999,"lng":46}"#.utf8))
        precondition(unsafe.url == nil)
        print("PASS: Store response, null metadata, store ID routing, category query, follow POST and validated directions")
        try await viewModel(store: store)
    }

    private static func viewModel(store: HomeMerchant) async throws {
        let service = MerchantTestService()
        var token: String? = "session"
        var cached = 0
        let model = HomeMerchantViewModel(offer: store.offers[0], service: service, currentToken: { token }, onLoad: { _ in cached += 1 })
        let first = Task { await model.load(language: "ar") }
        await service.waitForStores(1)
        precondition(model.isLoading && model.offers.isEmpty)
        await model.load(language: "ar")
        let initialCount = await service.storeCount
        precondition(initialCount == 1)
        await service.resolve(0, store: store)
        await first.value
        precondition(model.merchant?.id == 78 && model.offers.count == 1 && cached == 1)

        model.selectCategory(1)
        let category = Task { await model.load(language: "ar") }
        await service.waitForStores(2)
        precondition(model.offers.isEmpty, "Old category offers must not appear below the newly selected chip")
        model.selectCategory(2)
        let newer = Task { await model.load(language: "en") }
        await service.waitForStores(3)
        var empty = store
        empty.offers = []
        await service.resolve(2, store: empty)
        await newer.value
        await service.resolve(1, store: store)
        await category.value
        precondition(model.offers.isEmpty && model.selectedCategoryID == 2 && cached == 2)

        model.selectCategory(17)
        let failed = Task { await model.load(language: "en") }
        await service.waitForStores(4)
        await service.fail(3)
        await failed.value
        precondition(model.error != nil && model.merchant != nil && model.offers.isEmpty)
        let retry = Task { await model.load(language: "en", force: true) }
        await service.waitForStores(5)
        await service.resolve(4, store: store)
        await retry.value
        precondition(model.error == nil && model.offers.count == 1 && model.selectedCategoryID == nil)

        token = nil
        await model.toggleFollow(language: "en")
        precondition(model.showsLogin && !model.isFollowing)
        token = "session"
        let follow = Task { await model.toggleFollow(language: "en") }
        await service.waitForFollows(1)
        precondition(model.isUpdatingFollow && !model.isFollowing)
        await model.toggleFollow(language: "en")
        await service.finishFollow(success: false)
        await follow.value
        precondition(!model.isFollowing && model.followError != nil && !model.isUpdatingFollow)
        let successfulFollow = Task { await model.toggleFollow(language: "en") }
        await service.waitForFollows(2)
        await service.finishFollow(success: true)
        await service.waitForStores(6)
        var followed = store
        followed.isFollowed = true
        followed.followersCount = 1
        await service.resolve(5, store: followed)
        await successfulFollow.value
        precondition(model.isFollowing && model.merchant?.followersCount == 1 && model.followError == nil)

        let staleSession = Task { await model.load(language: "en", force: true) }
        await service.waitForStores(7)
        token = "different-session"
        await service.resolve(6, store: store)
        await staleSession.value
        precondition(model.isFollowing, "A prior session's response cannot overwrite current follow state")
        let cancelled = Task { await model.load(language: "en", force: true) }
        await service.waitForStores(8)
        cancelled.cancel()
        await service.resolve(7, store: store)
        await cancelled.value
        precondition(model.isFollowing && !model.isLoading)
        print("PASS: Merchant loading, filter races, retry, guest follow, duplicate mutation prevention, follow failure/success, cancellation and session protection")
    }
}

private actor MerchantTestService: MerchantServicing {
    private var stores: [CheckedContinuation<HomeMerchant, Error>] = []
    private var follow: CheckedContinuation<Void, Error>?
    private var followCount = 0
    var storeCount: Int { stores.count }

    func store(id: Int, categoryID: Int?, token: String?, language: String) async throws -> HomeMerchant {
        precondition(id == 78, "Use the store ID, not coupon ID 197")
        return try await withCheckedThrowingContinuation { stores.append($0) }
    }
    func toggleFollow(id: Int, token: String, language: String) async throws {
        precondition(id == 78)
        followCount += 1
        try await withCheckedThrowingContinuation { follow = $0 }
    }
    func waitForStores(_ count: Int) async { while stores.count < count { await Task.yield() } }
    func waitForFollows(_ count: Int) async { while followCount < count { await Task.yield() } }
    func resolve(_ index: Int, store: HomeMerchant) { stores[index].resume(returning: store) }
    func fail(_ index: Int) { stores[index].resume(throwing: APIError.invalidResponse) }
    func finishFollow(success: Bool) {
        if success { follow?.resume() } else { follow?.resume(throwing: APIError.invalidResponse) }
        follow = nil
    }
}
