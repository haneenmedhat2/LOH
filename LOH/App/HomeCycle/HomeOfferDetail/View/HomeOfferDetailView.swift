import SwiftUI

struct HomeOfferDetailView: View {
    @EnvironmentObject private var coordinator: HomeCoordinator
    @ObservedObject private var language = AppLanguageManager.shared
    @StateObject private var viewModel: HomeOfferDetailViewModel

    init(viewModel: @autoclosure @escaping () -> HomeOfferDetailViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel())
    }

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                gallery
                    .frame(height: min(geometry.size.width * 238 / 390, geometry.size.height * 0.38))
                    .overlay(alignment: .top) {
                        LinearGradient(
                            colors: [.black.opacity(0.25), .clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: 100)
                        .allowsHitTesting(false)
                    }

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        if let offer = viewModel.offer {
                            HomeOfferSummary(
                                offer: offer,
                                showsStore: viewModel.canShowStore,
                                onStore: {
                                    coordinator.show(.merchant(offer))
                                },
                                showsPricing: viewModel.hasLoadedDetails
                            )
                            if viewModel.hasLoadedDetails {
                                HomeOfferContent(offer: offer)
                            }
                        }
                        if !viewModel.hasLoadedDetails {
                            loadingContent
                        }
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .background(AppColor.surface)
            }
            .frame(width: geometry.size.width, height: geometry.size.height, alignment: .top)
        }
        .ignoresSafeArea(.container, edges: .top)
        .background(AppColor.surface.ignoresSafeArea())
        .foregroundStyle(AppColor.text)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(false)
        .toolbar(.visible, for: .navigationBar)
        .toolbarBackground(.hidden, for: .navigationBar)
        .appNativeNavigationAppearance(photo: true)
        .toolbar {
            if let offer = viewModel.offer {
                HomePhotoNavigation(
                    shareText: shareText(for: offer),
                    shareURL: shareURL(for: offer),
                    favorite: viewModel.isFavorite,
                    onFavorite: viewModel.toggleFavorite,
                    separateBackgrounds: true
                )
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if let offer = viewModel.offer, viewModel.hasLoadedDetails {
                HomeOfferPurchaseBar(offer: offer, isEnabled: viewModel.canPurchase) {
                    if let offer = viewModel.purchaseOffer() {
                        coordinator.show(.review(offer))
                    }
                }
            } else {
                purchasePlaceholder
            }
        }
        .toolbar(.hidden, for: .tabBar)
        .task(id: language.apiLanguage) {
            await viewModel.load(language: language.apiLanguage)
        }
        .sheet(isPresented: $viewModel.showsLogin) {
            if let offer = viewModel.offer {
                HomeLoginSheet(offer: offer)
            }
        }
        .logScreen("HomeOfferDetailView")
    }

    private func shareText(for offer: HomeOffer) -> String {
        let title = "\(offer.displayMerchant) — \(offer.displayTitle)"
        let price = homeMoney(offer.price, currency: offer.currency)
        return [title, price].joined(separator: "\n")
    }

    private func shareURL(for offer: HomeOffer) -> URL? {
        URL(string: shareURLString(for: offer))
    }

    private func shareURLString(for offer: HomeOffer) -> String {
        validShareURL(offer.shareLink) ?? "https://upgrade.loh.com.sa/shareCoupon/\(offer.id)"
    }

    private func validShareURL(_ value: String?) -> String? {
        guard let value = value?.trimmingCharacters(in: .whitespacesAndNewlines),
              let url = URL(string: value),
              ["http", "https"].contains(url.scheme?.lowercased() ?? ""),
              let host = url.host, !host.isEmpty else {
            return nil
        }
        return url.absoluteString
    }

    @ViewBuilder private var gallery: some View {
        if let offer = viewModel.offer {
            HomeOfferGallery(offer: offer)
        } else {
            HomePhoto(asset: "")
        }
    }

    private var loadingContent: some View {
        VStack(spacing: 20) {
            if let error = viewModel.error {
                HomeAPIError(message: error) {
                    Task {
                        await viewModel.load(language: language.apiLanguage, force: true)
                    }
                }
            } else {
                BrandLoaderView(size: 56)
                    .frame(maxWidth: .infinity)
                VStack(alignment: .leading, spacing: 16) {
                    RoundedRectangle(cornerRadius: 8)
                        .frame(height: 80)
                    RoundedRectangle(cornerRadius: 4)
                        .frame(height: 16)
                    RoundedRectangle(cornerRadius: 4)
                        .frame(height: 16)
                        .padding(.trailing, 60)
                }
                .foregroundStyle(AppColor.border.opacity(0.35))
                .accessibilityHidden(true)
            }
        }
    }

    private var purchasePlaceholder: some View {
        HStack(spacing: 20) {
            RoundedRectangle(cornerRadius: 8)
                .frame(width: 70, height: 36)
            Spacer()
            RoundedRectangle(cornerRadius: 16)
                .frame(width: 179, height: 65)
        }
        .foregroundStyle(AppColor.border.opacity(0.35))
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(AppColor.surface)
        .accessibilityHidden(true)
    }
}
