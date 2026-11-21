import SwiftUI

struct MainTabsRootView: View {
    @EnvironmentObject var tabsCoordinator: TabsCoordinator
    @ObservedObject private var language = AppLanguageManager.shared
    
    var body: some View {
        TabView(selection: $tabsCoordinator.selectedTab) {
            HomeRootView()
                .environmentObject(tabsCoordinator.homeCoordinator)
                .tabItem {
                    Label {
                        Text(homeText("home"))
                    } icon: {
                        (tabsCoordinator.selectedTab == .home ? LOHAsset.tabHome.image : HomeIcon.homeInactive.image)
                            .renderingMode(tabsCoordinator.selectedTab == .home ? .original : .template)
                    }
                }
                .tag(MainTab.home)
            HomeRootView(offersTab: true)
                .environmentObject(tabsCoordinator.offersCoordinator)
                .tabItem {
                    Label {
                        Text(homeText("offers"))
                    } icon: {
                        LOHAsset.tabOffers.image
                            .renderingMode(.template)
                    }
                }
                .tag(MainTab.offers)
            Group {
                
                PurchasesRootView()
                    .environmentObject(tabsCoordinator.purchasesModel)
                    .logScreen("PurchasesView")
            }
            .tabItem {
                Label {
                    Text(homeText("purchases"))
                } icon: {
                    LOHAsset.tabPurchases.image
                        .renderingMode(.template)
                }
            }
            .tag(MainTab.orders)
            MoreRootView()
                .tabItem {
                    Label {
                        Text("more.My account".localized)
                    } icon: {
                        LOHAsset.tabAccount.image
                            .renderingMode(.template)
                    }
                }
                .tag(MainTab.more)
        }
        .overlay { HomeFavoriteFeedback(model: tabsCoordinator.homeModel) }
        .id(language.selectedLanguage)
        .environmentObject(tabsCoordinator.homeModel)
        .environmentObject(tabsCoordinator.moreCoordinator)
        .environment(\.layoutDirection, language.layoutDirection)
        .environment(\.locale, Locale(identifier: language.selectedLanguage))
        .tint(AppColor.primary)
    }
}
