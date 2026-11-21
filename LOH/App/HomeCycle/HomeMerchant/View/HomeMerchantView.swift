import SwiftUI

struct HomeMerchantView: View {
    @EnvironmentObject private var coordinator: HomeCoordinator
    @ObservedObject private var language = AppLanguageManager.shared
    @StateObject private var viewModel: HomeMerchantViewModel

    init(viewModel: @autoclosure @escaping () -> HomeMerchantViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel())
    }

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                HomeMerchantHeader(cover: viewModel.merchant?.cover)
                    .frame(height: min(geometry.size.width * 220 / 390, geometry.size.height * 0.36))

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 8) {
                        HomeMerchantAvatar(
                            image: viewModel.merchant?.image ?? viewModel.seed?.store?.image
                                ?? viewModel.seed?.merchantImage,
                            isNawaPreview: viewModel.seed.map { !$0.isRemote && $0.merchant == "Nawa Café" } ?? false
                        )
                        .padding(.top, 12)

                        merchantContent
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height, alignment: .top)
        }
        .ignoresSafeArea(.container, edges: .top)
        .background(AppColor.canvas.ignoresSafeArea())
        .foregroundStyle(AppColor.text)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(false)
        .toolbar(.visible, for: .navigationBar, .tabBar)
        .toolbarBackground(.hidden, for: .navigationBar)
        .appNativeNavigationAppearance(photo: true)
        .toolbar {
            HomePhotoNavigation(
                shareText: merchantShareText,
                shareURL: merchantShareURL,
                separateBackgrounds: true)
        }
        .task(id: "\(language.apiLanguage):\(viewModel.selectedCategoryID ?? -1)") {
            await viewModel.load(language: language.apiLanguage)
        }
        .sheet(isPresented: $viewModel.showsLogin) {
            HomeLoginSheet(hint: "loginFollowHint", destination: merchantDestination)
                .environment(\.layoutDirection, language.layoutDirection)
                .presentationBackground(AppColor.surface)
        }
        .alert(
            homeText("follow"),
            isPresented: Binding(
                get: { viewModel.followError != nil },
                set: { if !$0 { viewModel.followError = nil } }
            )
        ) {
            Button(homeText("close"), role: .cancel) { viewModel.followError = nil }
        } message: {
            Text(viewModel.followError ?? "")
        }
        .logScreen("HomeMerchantView")
    }

    private var merchantContent: some View {
        VStack(spacing: 20) {
            if let merchant = viewModel.merchant {
                HomeMerchantInfo(
                    merchant: merchant,
                    isFollowing: viewModel.isFollowing,
                    isUpdatingFollow: viewModel.isUpdatingFollow,
                    canFollow: !viewModel.isLoading && viewModel.error == nil
                ) {
                    Task { await viewModel.toggleFollow(language: language.apiLanguage) }
                }
                HomeMerchantOffers(
                    merchant: merchant,
                    offers: viewModel.offers,
                    selectedCategoryID: viewModel.selectedCategoryID,
                    isLoading: viewModel.isLoading,
                    error: viewModel.error,
                    canSelectCategory: !viewModel.isUpdatingFollow,
                    onCategory: viewModel.selectCategory,
                    onRetry: reload,
                    onOffer: { coordinator.show(.offer($0)) }
                )
                HomeMerchantLocationCard(merchant: merchant)
            } else if let error = viewModel.error {
                HomeAPIError(message: error, retry: reload)
            } else {
                if let name = viewModel.seed?.displayMerchant {
                    Text(name).font(AppFont.extraBold(size: 22))
                }
                BrandLoaderView(size: 56)
                    .frame(maxWidth: .infinity, minHeight: 100)
            }
        }
    }

    private func reload() {
        Task { await viewModel.load(language: language.apiLanguage, force: true) }
    }

    private var merchantDestination: GuestDestination? {
        if let seed = viewModel.seed { return .home(.merchant(seed)) }
        if let id = viewModel.merchantID { return .home(.merchantID(id)) }
        return nil
    }

    private var merchantShareText: String {
        viewModel.merchant?.name ?? viewModel.seed?.displayMerchant ?? ""
    }

    private var merchantShareURL: URL? {
        let id = viewModel.merchant?.id ?? viewModel.merchantID
        guard let id, id > 0 else { return nil }
        let fallback = "https://upgrade.loh.com.sa/shareStore/\(id)"
        let value = viewModel.merchant?.shareLink?.trimmingCharacters(in: .whitespacesAndNewlines)
        if let url = value.flatMap({ URL(string: $0) }),
           ["http", "https"].contains(url.scheme?.lowercased() ?? ""),
           url.host?.isEmpty == false {
            return url
        }
        return URL(string: fallback)
    }
}
