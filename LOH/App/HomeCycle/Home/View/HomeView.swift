import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var model: HomeViewModel
    @EnvironmentObject private var notifications: NotificationsViewModel
    @EnvironmentObject private var coordinator: HomeCoordinator
    @State private var categoryID: Int?
    @ObservedObject private var language = AppLanguageManager.shared
    @Environment(\.openURL) private var openURL
    @State private var sheet: HomeSheet?
    @State private var banner = 0
    private var nearby: [HomeOffer] { model.nearby }
    private var showsLoadingContent: Bool {
        model.loading || (!model.hasLoaded && model.error == nil)
    }
    private var loadKey: String { "\(language.selectedLanguage)-\(model.resolvedCityID ?? -1)-\(categoryID ?? -1)" }
    private var name: String {
        model.user?.name ?? UserDefaults.user?.name ?? homeText("guest")
    }
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                if let error = model.error {
                    HomeAPIError(message: error) {
                        Task {
                            await reload()
                        }
                    }
                }
                header
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 12)
                HStack(spacing: 8) {
                    HomeFilterButton(count: model.filters.count) {
                        sheet = .filters
                    }
                    Button {
                        coordinator.show(.search)
                    } label: {
                        HStack(spacing: 12) {
                            Text(homeText("searchHint"))
                                .font(AppFont.regular(size: 14))
                                .foregroundStyle(AppColor.mutedText)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            LOHAsset.search.image
                                .resizable()
                                .scaledToFit()
                                .frame(width: 18, height: 18)
                        }
                        .padding(.horizontal, 16)
                        .frame(height: 44)
                        .background(AppColor.surface, in: RoundedRectangle(cornerRadius: 16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color(white: 0.94), lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(0.1), radius: 1, y: 1)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16)
                categories
                    .padding(.top, 16)
                if showsLoadingContent {
                    HomeSearchLoadingView()
                        .padding(.horizontal, 16)
                        .padding(.vertical, 16)
                } else {
                    loadedContent
                }
            }
        }
        .background(
            AppColor.canvas
                .ignoresSafeArea()
        )
        .toolbar(.hidden, for: .navigationBar)
        .task(id: loadKey) {
            await reload()
        }
        .appRefreshable {
            await reload()
        }
        .sheet(item: $sheet) { sheet in
            switch sheet {
            case .city: HomeCitySheet()
            case .filters:
                HomeFilterSheet(initialCategoryID: categoryID) {
                    coordinator.show(.feed(.search, nil))
                }
            case .cashback: cashbackInfo
            }
        }
    }
    private var loadedContent: some View {
        VStack(spacing: 0) {
            if !model.banners.isEmpty {
                hero
                    .padding(.horizontal, 16)
                    .padding(.top, 20)
            }
            sectionTitle("nearby", icon: .pin) {
                coordinator.show(.feed(.nearby, categoryID))
            }
            .padding(.top, 20)
            if nearby.isEmpty {
                if model.error == nil {
                    Text(homeText("noResults"))
                        .font(AppFont.regular(size: 14))
                        .foregroundStyle(AppColor.secondaryText)
                        .padding(24)
                }
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(alignment: .top, spacing: 12) {
                        ForEach(nearby.prefix(5)) { offer in
                            HomeOfferCard(offer: offer) {
                                coordinator.show(.offer(offer))
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 4)
                }
                .padding(.top, 12)
            }
            if model.cashback != nil {
                cashback
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 20)
            }
            sectionTitle("endingSoon", icon: .clock) {
                coordinator.show(.feed(.endingSoon, categoryID))
            }
            if model.endingSoon.isEmpty && model.error == nil {
                Text(homeText("noResults"))
                    .font(AppFont.regular(size: 14))
                    .foregroundStyle(AppColor.secondaryText)
                    .padding(24)
            }
            LazyVStack(spacing: 12) {
                ForEach(model.endingSoon) { offer in
                    HomeEndingSoonCard(offer: offer, expiresAt: offer.expiresAt) {
                        coordinator.show(.offer(offer))
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 24)
        }
    }
    private var header: some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 3) {
                Text(model.user?.greeting ?? (UserDefaults.accessToken == nil ? homeText("guestAccountTitle") : homeFormat("greetingFormat", name)))
                    .font(AppFont.bold(size: 14))
                    .lineLimit(1)
                Text(model.user?.greetingSubtitle ?? homeText("saveToday"))
                    .font(AppFont.regular(size: 12))
                    .foregroundStyle(AppColor.secondaryText)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Button {
                coordinator.show(.favorites)
            } label: {
                HomeIcon.heart.view(20, color: .black)
                    .frame(width: 40, height: 40)
                    .background(AppColor.surface, in: Circle())
                    .overlay(Circle().stroke(Color(white: 0.94)))
                    .shadow(color: .black.opacity(0.1), radius: 1, y: 1)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(homeText("favorites"))
            Button {
                coordinator.show(.notifications)
            } label: {
                HomeIcon.bell.view(20)
                    .frame(width: 40, height: 40)
                    .background(AppColor.surface, in: Circle())
                    .overlay(
                        Circle()
                            .stroke(Color(white: 0.94))
                    )
                    .overlay(alignment: .topTrailing) {
                        if notificationCount > 0 && !notifications.requiresSignIn {
                            Text(notificationBadgeText)
                                .font(AppFont.bold(size: 10))
                                .foregroundStyle(.white)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                                .frame(minWidth: 18, minHeight: 18)
                                .padding(.horizontal, 2)
                                .background(AppColor.primary, in: Capsule())
                                .overlay(
                                    Capsule()
                                        .stroke(.white, lineWidth: 2)
                                )
                                .offset(x: 6, y: -6)
                                .zIndex(1)
                        }
                    }
                    .shadow(color: .black.opacity(0.1), radius: 1, y: 1)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(homeText("notifications"))
            Button {
                sheet = .city
            } label: {
                HStack(spacing: 6) {
                    LOHAsset.pin.image
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 14, height: 14)
                        .foregroundStyle(AppColor.primary)
                    Text(model.displayedCityName)
                        .font(AppFont.medium(size: 13))
                    LOHAsset.chevronDown.image
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 12, height: 12)
                }
                .padding(.horizontal, 12)
                .frame(height: 34)
                .background(AppColor.surface, in: Capsule())
                .overlay(
                    Capsule()
                        .stroke(Color(white: 0.94), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.1), radius: 1, y: 1)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(homeText("chooseCity"))
        }
    }
    private var notificationCount: Int {
        notifications.count ?? model.notificationsCount
    }
    private var notificationBadgeText: String {
        notificationCount > 99 ? "99+" : "\(notificationCount)"
    }
    private func reload() async {
        banner = 0
        async let home: Void = model.load(language: language.apiLanguage, categoryID: categoryID)
        async let count: Void = notifications.refreshCount(language: language.apiLanguage)
        _ = await (home, count)
    }
    private var categories: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: 12) {
                ForEach(model.categories) { item in
                    Button {
                        categoryID = item.id
                    } label: {
                        VStack(spacing: 6) {
                            HomePhoto(asset: item.image ?? "")
                                .frame(width: 48, height: 48)
                                .clipShape(Circle())
                                .overlay(
                                    Circle()
                                        .stroke(
                                            categoryID == item.id ? AppColor.primary : AppColor.border, lineWidth: 1))
                            Text(item.name)
                                .font(AppFont.regular(size: 11))
                                .foregroundStyle(categoryID == item.id ? AppColor.primary : AppColor.secondaryText)
                        }
                        .frame(minWidth: 48, minHeight: 70.5)
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(categoryID == item.id ? .isSelected : [])
                }
            }
            .padding(.horizontal, 16)
        }
    }
    private var hero: some View {
        HomeBannerCarousel(banners: model.banners, selection: $banner, action: bannerAction)
    }
    private func bannerAction(_ item: HomeBanner) -> (() -> Void)? {
        if item.type != "outside", let id = item.couponID, id > 0 {
            return {
                coordinator.show(.offerID(String(id)))
            }
        }
        if item.type != "inside", let link = item.link, let url = URL(string: link),
            ["https", "http"].contains(url.scheme?.lowercased() ?? ""), let host = url.host, !host.isEmpty
        {
            return {
                openURL(url)
            }
        }
        return nil
    }
    private func sectionTitle(_ key: String, icon: HomeIcon, action: @escaping () -> Void) -> some View {
        HStack {
            HStack(spacing: 6) {
                Text(homeText(key))
                    .font(AppFont.bold(size: 17))
                icon.view(16, color: AppColor.primary)
            }
            Spacer()
            Button(homeText("viewAll"), action: action)
                .font(AppFont.medium(size: 13))
                .foregroundStyle(AppColor.primary)
        }
        .padding(.horizontal, 16)
    }
    private var cashback: some View {
        HStack(spacing: 12) {
            cashbackImage(size: 24)
                .frame(width: 48, height: 48)
                .background(AppColor.successSurface, in: Circle())
            VStack(alignment: .leading, spacing: 4) {
                Text(model.cashback?.title ?? homeText("cashbackTitle"))
                    .font(AppFont.bold(size: 14))
                Text(model.cashback?.subtitle ?? "")
                    .font(AppFont.regular(size: 12))
                    .foregroundStyle(AppColor.secondaryText)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Button(model.cashback?.button ?? homeText("learnMore")) {
                sheet = .cashback
            }
            .font(AppFont.medium(size: 12))
            .foregroundStyle(AppColor.success)
            .padding(8)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(AppColor.success, lineWidth: 1))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(red: 240 / 255, green: 1, blue: 244 / 255), in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(white: 0.94)))
    }
    @ViewBuilder
    private func cashbackImage(size: CGFloat) -> some View {
        if let image = model.cashback?.image, !image.isEmpty {
            HomePhoto(asset: image)
                .frame(width: size, height: size)
                .clipShape(Circle())
        } else {
            HomeIcon.cashback.view(size)
        }
    }
    private var cashbackInfo: some View {
        VStack(spacing: 20) {
            cashbackImage(size: 48)
            Text(model.cashback?.title ?? homeText("cashbackTitle"))
                .font(AppFont.heading)
            Text(model.cashback?.subtitle ?? "")
                .multilineTextAlignment(.center)
                .foregroundStyle(AppColor.secondaryText)
            MainAppButton(
                title: homeText("browseOffers"),
                action: {
                    sheet = nil
                    coordinator.show(.results("", .all))
                })
        }
        .padding(24)
        .presentationDetents([.medium])
        .presentationBackground(AppColor.surface)
        .presentationDragIndicator(.visible)
    }
}
