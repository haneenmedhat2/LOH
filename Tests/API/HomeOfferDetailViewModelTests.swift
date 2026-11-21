import Combine
import Foundation

@MainActor enum HomeOfferDetailViewModelTests {
    static func run() async throws {
        let fixture = try HomeServiceTests.fixture("coupon-196")
        let offer = try JSONDecoder().decode(APIEnvelope<HomeOffer>.self, from: Data(fixture.utf8)).data!
        let service = DetailTestService()
        var cached: [HomeOffer] = []
        var token: String? = "detail-session"
        let favorites = CurrentValueSubject<Set<String>, Never>([])
        let model = HomeOfferDetailViewModel(
            id: "196", service: service, currentToken: { token },
            favoriteIDs: favorites.eraseToAnyPublisher(),
            onLoad: { cached.append($0) },
            onFavoriteToggle: { id in
                var ids = favorites.value
                if !ids.insert(id).inserted { ids.remove(id) }
                favorites.send(ids)
            }
        )

        let initial = Task { await model.load(language: "ar") }
        await service.waitForRequests(1)
        precondition(model.isLoading && model.offer == nil && !model.canPurchase)
        await model.load(language: "ar")
        let activeCount = await service.requestCount
        precondition(activeCount == 1, "Do not duplicate an active request")
        await service.resolve(0, with: .success(offer))
        await initial.value
        precondition(model.offer == offer && model.error == nil && !model.isLoading)
        precondition(model.canShowStore && !model.canPurchase && model.purchaseOffer() == nil)
        precondition(cached.count == 1)
        await model.load(language: "ar")
        let loadedCount = await service.requestCount
        precondition(loadedCount == 1, "Returning from the store keeps loaded details")
        model.toggleFavorite()
        precondition(model.isFavorite && favorites.value == ["196"])
        favorites.send([])
        precondition(!model.isFavorite, "Changes outside details must update its heart")

        let refresh = Task { await model.load(language: "ar", force: true) }
        await service.waitForRequests(2)
        await service.resolve(1, with: .failure(APIError.invalidResponse))
        await refresh.value
        precondition(model.error != nil && model.offer != nil && !model.isLoading && !model.hasLoadedDetails)
        precondition(!model.canPurchase, "Retained content cannot be purchased after a failed refresh")
        let retry = Task { await model.load(language: "ar") }
        await service.waitForRequests(3)
        await service.resolve(2, with: .success(offer))
        await retry.value
        precondition(model.offer != nil && model.error == nil)

        // The transport deliberately completes superseded requests, even after cancellation.
        let old = Task { await model.load(language: "ar", force: true) }
        await service.waitForRequests(4)
        let newer = Task { await model.load(language: "en") }
        await service.waitForRequests(5)
        var english = offer
        english.descriptionText = "English details"
        await service.resolve(4, with: .success(english))
        await newer.value
        await service.resolve(3, with: .success(offer))
        await old.value
        precondition(model.offer?.descriptionText == "English details")

        let cancelled = Task { await model.load(language: "ar") }
        await service.waitForRequests(6)
        cancelled.cancel()
        await service.resolve(5, with: .success(offer))
        await cancelled.value
        precondition(model.offer == english && model.error == nil && !model.isLoading && !model.hasLoadedDetails)
        let afterCancellation = Task { await model.load(language: "ar") }
        await service.waitForRequests(7)
        token = "new-session"
        await service.resolve(6, with: .success(offer))
        await afterCancellation.value
        precondition(model.offer == english && !model.hasLoadedDetails, "Discard responses belonging to the previous session")

        let sessionReload = Task { await model.load(language: "ar") }
        await service.waitForRequests(8)
        var available = offer
        available.available = true
        await service.resolve(7, with: .success(available))
        await sessionReload.value
        precondition(model.canPurchase && model.purchaseOffer()?.id == "196")
        token = nil
        precondition(model.purchaseOffer() == nil && model.showsLogin)

        let preview = HomeOfferDetailViewModel(id: "nawa", offer: .samples[0], service: service, currentToken: { nil })
        await preview.load(language: "ar")
        precondition(preview.offer?.id == "nawa")
        let finalCount = await service.requestCount
        precondition(finalCount == 8, "Local previews must not call coupon/nawa")

        let summaryModel = HomeOfferDetailViewModel(id: "196", offer: available, service: service, currentToken: { "session" })
        precondition(summaryModel.offer == available && !summaryModel.hasLoadedDetails)
        precondition(!summaryModel.canPurchase && summaryModel.purchaseOffer() == nil, "A list summary is not confirmed detail data")
        let summaryLoad = Task { await summaryModel.load(language: "ar") }
        await service.waitForRequests(9)
        precondition(summaryModel.offer?.asset == available.asset && summaryModel.isLoading)
        await service.resolve(8, with: .failure(APIError.invalidResponse))
        await summaryLoad.value
        precondition(summaryModel.offer?.id == "196" && summaryModel.error != nil && !summaryModel.canPurchase)
        let summaryRetry = Task { await summaryModel.load(language: "ar", force: true) }
        await service.waitForRequests(10)
        await service.resolve(9, with: .success(available))
        await summaryRetry.value
        precondition(summaryModel.hasLoadedDetails && summaryModel.canPurchase)
        print("PASS: Detail model summary-first rendering, purchase gating, retry, deduplication, stale language/session rejection, cancellation and favorites")
    }
}

private actor DetailTestService: HomeServicing {
    private var requests: [CheckedContinuation<HomeOffer, Error>] = []
    var requestCount: Int { requests.count }

    func detail(id: String, token: String?, language: String) async throws -> HomeOffer {
        precondition(id == "196")
        return try await withCheckedThrowingContinuation { requests.append($0) }
    }

    func waitForRequests(_ count: Int) async {
        while requests.count < count { await Task.yield() }
    }

    func resolve(_ index: Int, with result: Result<HomeOffer, Error>) {
        requests[index].resume(with: result)
    }

    func home(cityID: Int?, categoryID: Int?, token: String?, language: String) async throws -> HomePageData {
        throw APIError.invalidResponse
    }
    func categories(language: String, token: String?) async throws -> [HomeAPICategory] { throw APIError.invalidResponse }
    func filters(language: String, token: String?) async throws -> [HomeFilterGroup] { throw APIError.invalidResponse }
    func offers(_ request: HomeSearchRequest, page: Int, token: String?, language: String) async throws -> HomeOfferPage {
        throw APIError.invalidResponse
    }
    func cities(language: String, token: String?) async throws -> [AuthOption] { throw APIError.invalidResponse }
}
