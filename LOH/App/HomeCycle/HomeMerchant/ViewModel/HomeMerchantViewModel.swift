import Combine
import Foundation

@MainActor
final class HomeMerchantViewModel: ObservableObject {
    @Published private(set) var merchant: HomeMerchant?
    @Published private(set) var isLoading = false
    @Published private(set) var error: String?
    @Published private(set) var isFollowing = false
    @Published private(set) var isUpdatingFollow = false
    @Published private(set) var selectedCategoryID: Int?
    @Published var showsLogin = false
    @Published var followError: String?

    let seed: HomeOffer?
    let merchantID: Int?
    private let client: DefaultResponseHandler
    private let currentToken: @MainActor () -> String?
    private let onLoad: (HomeMerchant) -> Void
    private let preview: HomeMerchant?
    private var generation = UUID()
    private var loadedContext: Context?
    private var requestedContext: Context?

    private struct Context: Equatable {
        let language: String
        let token: String?
        let categoryID: Int?
    }

    init(
        offer: HomeOffer,
        client: DefaultResponseHandler = DefaultResponseHandler(),
        preview: HomeMerchant? = nil,
        currentToken: @escaping @MainActor () -> String? = { UserDefaults.accessToken },
        onLoad: @escaping (HomeMerchant) -> Void = { _ in }
    ) {
        seed = offer
        merchantID = offer.store?.id
        self.client = client
        self.preview = preview
        self.currentToken = currentToken
        self.onLoad = onLoad
        merchant = preview
        isFollowing = preview?.isFollowed ?? false
    }

    init(
        merchantID: Int,
        client: DefaultResponseHandler = DefaultResponseHandler(),
        currentToken: @escaping @MainActor () -> String? = { UserDefaults.accessToken },
        onLoad: @escaping (HomeMerchant) -> Void = { _ in }
    ) {
        seed = nil
        self.merchantID = merchantID
        self.client = client
        preview = nil
        self.currentToken = currentToken
        self.onLoad = onLoad
    }

    var offers: [HomeOffer] {
        guard !isLoading, error == nil else { return [] }
        guard let preview else { return merchant?.offers ?? [] }
        guard let selectedCategoryID else { return preview.offers }
        return preview.offers.filter { $0.categoryID == selectedCategoryID }
    }

    func selectCategory(_ id: Int) {
        guard !isUpdatingFollow else { return }
        // The supplied store contract identifies All Categories with ID 17.
        selectedCategoryID = id == 17 ? nil : id
    }

    func load(language: String, force: Bool = false) async {
        guard preview == nil else { return }
        guard let id = merchantID, id > 0 else {
            error = APIError.invalidResponse.localizedDescription
            return
        }
        let context = Context(language: language, token: currentToken(), categoryID: selectedCategoryID)
        guard !(isLoading && requestedContext == context), force || loadedContext != context else { return }
        let requestGeneration = UUID()
        generation = requestGeneration
        requestedContext = context
        isLoading = true
        error = nil
        loadedContext = nil
        defer {
            if generation == requestGeneration { isLoading = false }
        }
        do {
            let result: HomeMerchant = try await client.data(
                from: MerchantEndpoints.store(id: id, categoryID: context.categoryID, token: context.token),
                language: language)
            try Task.checkCancellation()
            guard generation == requestGeneration, currentToken() == context.token else { return }
            guard result.id == id else { throw APIError.invalidResponse }
            merchant = result
            isFollowing = result.isFollowed
            loadedContext = context
            onLoad(result)
        } catch {
            guard generation == requestGeneration, currentToken() == context.token, !Task.isCancelled else { return }
            if !(error is CancellationError) { self.error = error.localizedDescription }
        }
    }

    func toggleFollow(language: String) async {
        guard !isUpdatingFollow, !isLoading, error == nil, let merchant else { return }
        if preview != nil {
            isFollowing.toggle()
            return
        }
        guard let token = currentToken() else {
            showsLogin = true
            return
        }
        isUpdatingFollow = true
        followError = nil
        let requestGeneration = generation
        defer { isUpdatingFollow = false }
        do {
            try await client.perform(
                MerchantEndpoints.toggleFollow(id: merchant.id, token: token), language: language)
            try Task.checkCancellation()
            guard currentToken() == token, requestGeneration == generation else { return }
            isFollowing.toggle()
            self.merchant?.isFollowed = isFollowing
            self.merchant?.followersCount = max(0, merchant.followersCount + (isFollowing ? 1 : -1))
            await load(language: language, force: true)
        } catch {
            guard currentToken() == token, requestGeneration == generation, !Task.isCancelled else { return }
            followError = error.localizedDescription
        }
    }
}
