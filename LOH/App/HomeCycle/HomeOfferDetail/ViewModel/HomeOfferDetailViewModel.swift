import Combine
import Foundation

/// Owns a single coupon's request, presentation state, and purchase eligibility.
@MainActor
final class HomeOfferDetailViewModel: ObservableObject {
    @Published private(set) var offer: HomeOffer?
    @Published private(set) var isLoading = false
    @Published private(set) var error: String?
    @Published private(set) var isFavorite = false
    @Published private(set) var hasLoadedDetails = false
    @Published var showsLogin = false

    let id: String
    private let client: DefaultResponseHandler
    private let currentToken: @MainActor () -> String?
    private let onLoad: (HomeOffer) -> Void
    private let onFavoriteToggle: ((String) -> Void)?
    private let isPreview: Bool
    private var favoriteSubscription: AnyCancellable?
    private var generation = UUID()
    private var requestedContext: Context?
    private var loadedContext: Context?

    private struct Context: Equatable {
        let language: String
        let token: String?
    }

    init(
        id: String,
        offer: HomeOffer? = nil,
        client: DefaultResponseHandler = DefaultResponseHandler(),
        currentToken: @escaping @MainActor () -> String? = { UserDefaults.accessToken },
        favoriteIDs: AnyPublisher<Set<String>, Never>? = nil,
        onLoad: @escaping (HomeOffer) -> Void = { _ in },
        onFavoriteToggle: ((String) -> Void)? = nil
    ) {
        self.id = id
        self.client = client
        self.currentToken = currentToken
        self.onLoad = onLoad
        self.onFavoriteToggle = onFavoriteToggle
        isPreview = offer?.isRemote == false
        self.offer = offer
        hasLoadedDetails = isPreview
        isFavorite = offer?.isFavorite ?? false
        favoriteSubscription = favoriteIDs?
            .sink { [weak self] ids in
                self?.isFavorite = ids.contains(id)
            }
    }

    var canPurchase: Bool { hasLoadedDetails && offer?.available == true && !isLoading }
    var canShowStore: Bool {
        guard hasLoadedDetails, let offer else { return false }
        return (!offer.isRemote || (offer.store?.id ?? 0) > 0)
            && !offer.merchant.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func load(language: String, force: Bool = false) async {
        guard !isPreview else { return }
        let context = Context(language: language, token: currentToken())
        guard !(isLoading && requestedContext == context), force || loadedContext != context else { return }

        let requestGeneration = UUID()
        generation = requestGeneration
        requestedContext = context
        isLoading = true
        error = nil
        hasLoadedDetails = false
        loadedContext = nil
        defer {
            if generation == requestGeneration { isLoading = false }
        }

        do {
            guard let numericID = Int(id), numericID > 0 else { throw APIError.invalidResponse }
            let result: HomeOffer = try await client.data(
                from: HomeEndpoints.coupon(id: numericID, token: context.token), language: language)
            try Task.checkCancellation()
            guard generation == requestGeneration, currentToken() == context.token else { return }
            guard result.id == id else { throw APIError.invalidResponse }
            offer = result
            loadedContext = context
            hasLoadedDetails = true
            if favoriteSubscription == nil { isFavorite = result.isFavorite ?? isFavorite }
            onLoad(result)
        } catch {
            guard generation == requestGeneration, currentToken() == context.token, !Task.isCancelled else { return }
            if !(error is CancellationError) { self.error = error.localizedDescription }
        }
    }

    func toggleFavorite() {
        guard offer != nil else { return }
        if let onFavoriteToggle {
            onFavoriteToggle(id)
        } else {
            isFavorite.toggle()
        }
    }

    func purchaseOffer() -> HomeOffer? {
        guard canPurchase else { return nil }
        guard currentToken() != nil else {
            showsLogin = true
            return nil
        }
        return offer
    }
}
