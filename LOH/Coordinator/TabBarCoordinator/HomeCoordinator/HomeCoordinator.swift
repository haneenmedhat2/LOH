import SwiftUI

@MainActor
final class HomeCoordinator: BaseCoordinator<HomeRoute> {
    @Published var showsLogin = false
    private(set) var loginRoute: HomeRoute?
    var loginHint: String {
        switch loginRoute {
        case .favorites: return "loginFavoriteHint"
        case .notifications: return "loginNotificationsHint"
        default: return "loginBuyHint"
        }
    }
    let model: HomeViewModel
    init(model: HomeViewModel) {
        self.model = model
        super.init()
    }

    @ViewBuilder
    func destination(for route: HomeRoute) -> some View {
        switch route {
        case .feed(let feed, let categoryID): HomeSearchView(showsResults: true, feed: feed, categoryID: categoryID)
        case .offerID(let id):
            HomeOfferDetailView(viewModel: self.offerDetailModel(id: id))
        case .search:
            HomeSearchView()
                .logScreen("HomeSearchView")
        case .results(let query, let category):
            HomeSearchView(initialQuery: query, initialCategory: category, showsResults: true)
                .logScreen("HomeSearchView")
        case .offer(let offer):
            HomeOfferDetailView(viewModel: self.offerDetailModel(id: offer.id, offer: offer))
        case .merchant(let offer):
            HomeMerchantView(viewModel: self.merchantModel(offer: offer))
        case .merchantID(let id):
            HomeMerchantView(viewModel: self.merchantModel(id: id))
        case .review(let offer):
            HomeOrderReviewView(offer: offer)
                .logScreen("HomeOrderReviewView")
        case .payment(let offer, let quantity):
            HomePaymentView(offer: offer, quantity: quantity)
                .logScreen("HomePaymentView")
        case .paymentProcessing(let order):
            HomePaymentProcessingView(viewModel: HomePaymentProcessingViewModel(order: order))
        case .paymentSuccess(let receipt): HomePaymentSuccessView(receipt: receipt)
        case .qrCode(let receipt): HomeQRCodeView(receipt: receipt)
        case .purchaseCode(let id, let status): PurchaseCodeView(id: id, status: status)
        case .favorites:
            HomeFavoritesView()
                .logScreen("HomeFavoritesView")
        case .notifications:
            HomeNotificationsView()
                .logScreen("HomeNotificationsView")
        }
    }

    private func merchantModel(offer: HomeOffer) -> HomeMerchantViewModel {
        HomeMerchantViewModel(
            offer: offer,
            preview: HomeMerchantPreview.make(
                offer: offer, offers: model.offers, language: AppLanguageManager.shared.apiLanguage
            ),
            onLoad: { [model] merchant in
                model.cache(merchant.offers)
            }
        )
    }

    private func merchantModel(id: Int) -> HomeMerchantViewModel {
        HomeMerchantViewModel(merchantID: id, client: model.client, onLoad: { [model] merchant in
            model.cache(merchant.offers)
        })
    }

    private func offerDetailModel(id: String, offer: HomeOffer? = nil) -> HomeOfferDetailViewModel {
        HomeOfferDetailViewModel(
            id: id,
            offer: offer,
            client: model.client,
            favoriteIDs: model.$favorites.eraseToAnyPublisher(),
            onLoad: { [model] offer in
                model.cache([offer])
            },
            onFavoriteToggle: { [model] id in
                model.toggleFavorite(id, language: AppLanguageManager.shared.apiLanguage)
            }
        )
    }
    func show(_ route: HomeRoute) {
        if UserDefaults.accessToken == nil {
            switch route {
            case .paymentProcessing(let order):
                loginRoute = .offer(order.offer)
                showsLogin = true
                return
            case .favorites, .notifications, .review, .payment:
                loginRoute = route
                showsLogin = true
                return
            default: break
            }
        }
        path.append(route)
    }
    func replaceTop(with route: HomeRoute) {
        if !path.isEmpty {
            path.removeLast()
        }
        path.append(route)
    }

    func finishCheckout(_ receipt: HomeCheckoutReceipt) {
        if let review = path.firstIndex(where: {
            if case .review = $0 { return true }
            return false
        }) {
            path.removeSubrange(review...)
        } else if !path.isEmpty {
            path.removeLast()
        }
        path.append(.paymentSuccess(receipt))
    }
}
