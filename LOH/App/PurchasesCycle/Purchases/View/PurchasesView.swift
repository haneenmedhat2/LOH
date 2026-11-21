import SwiftUI

struct PurchasesRootView: View {
    @EnvironmentObject private var model: PurchasesViewModel
    @ObservedObject private var language = AppLanguageManager.shared
    @State private var path: [PurchaseRoute] = []
    @State private var filter: PurchaseFilter = .all
    @EnvironmentObject private var app: AppCoordinator
    @EnvironmentObject private var tabs: TabsCoordinator

    var body: some View {
        NavigationStack(path: $path) {
            Group {
                if model.requiresSignIn {
                    PurchasesGuestView(
                        onLogin: { app.beginAuthentication(destination: .tab(.orders)) },
                        onRegister: { app.beginAuthentication(register: true, destination: .tab(.orders)) },
                        onBrowse: { tabs.selectedTab = .offers })
                } else {
                    purchasesContent
                }
            }
            .navigationDestination(for: PurchaseRoute.self) { route in
                if route.codeOnly {
                    PurchaseCodeView(id: route.id, status: route.status)
                } else {
                    PurchaseDetailView(id: route.id, status: route.status)
                }
            }
            .task(id: PurchaseLoadContext(filter: filter, language: language.apiLanguage, token: UserDefaults.accessToken)) {
                await model.reload(filter: filter, language: language.apiLanguage)
            }
        }
        .toolbar(path.isEmpty ? .visible : .hidden, for: .tabBar)
        .onChange(of: path.isEmpty) { isRoot in
            if isRoot { Task { await model.reload(filter: filter, language: language.apiLanguage) } }
        }
        .onChange(of: UserDefaults.accessToken) { _ in path = [] }
        .logScreen("PurchasesView")
    }

    private var purchasesContent: some View {
        VStack(spacing: 0) {
            Text(homeText("myPurchases"))
                .font(AppFont.navigationTitle)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(AppColor.surface)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(PurchaseFilter.allCases) {
                        filterButton($0)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .background(AppColor.surface)
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 16) {
                    if model.loading {
                        BrandLoaderView(size: 56)
                            .padding()
                    }
                    if let error = model.error {
                        HomeAPIError(message: error) {
                            Task {
                                await model.retry(language: language.apiLanguage)
                            }
                        }
                    }
                    ForEach(model.rows) { row in
                        PurchaseCard(coupon: row.coupon, fallbackStatus: model.filter.status) { codeOnly in
                            path.append(
                                PurchaseRoute(
                                    id: row.coupon.id,
                                    status: row.coupon.status ?? model.filter.status,
                                    codeOnly: codeOnly))
                        }
                    }
                    if model.hasLoaded && model.rows.isEmpty && !model.loading && model.error == nil {
                        Text(homeText("noPurchasesStatus"))
                            .font(AppFont.regular(size: 14))
                            .foregroundStyle(AppColor.secondaryText)
                            .padding(32)
                    }
                    if model.loadingMore {
                        BrandLoaderView(size: 56)
                            .padding()
                    } else if model.hasMore && model.error == nil {
                        Button("api.loadMore".localized) {
                            Task {
                                await model.loadMore()
                            }
                        }
                        .font(AppFont.medium(size: 14))
                        .foregroundStyle(AppColor.primary)
                        .padding()
                    }
                }
                .padding(16)
                .frame(maxWidth: 600)
                .frame(maxWidth: .infinity)
            }
            .appRefreshable {
                await model.reload(filter: filter, language: language.apiLanguage)
            }
        }
        .background(
            AppColor.accountCanvas
                .ignoresSafeArea()
        )
        .foregroundStyle(AppColor.text)
        .toolbar(.hidden, for: .navigationBar)
    }

    private func filterButton(_ value: PurchaseFilter) -> some View {
        let selected = filter == value
        return Button {
            filter = value
        } label: {
            HStack(spacing: 6) {
                Text(homeText(value.titleKey))
                    .font(AppFont.medium(size: 13))
                if let total = model.totals[value] {
                    Text(homeNumber(total))
                        .font(AppFont.medium(size: 10))
                        .padding(.horizontal, 5)
                        .frame(minWidth: 20, minHeight: 20)
                        .background(selected ? .white.opacity(0.25) : Color(.systemGray6), in: Capsule())
                }
            }
            .foregroundStyle(selected ? .white : AppColor.text)
            .padding(.horizontal, 12)
            .frame(height: 40)
            .background(selected ? AppColor.primary : AppColor.surface, in: RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(selected ? .clear : AppColor.border))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}
