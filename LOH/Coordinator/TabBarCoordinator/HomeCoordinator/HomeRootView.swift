import SwiftUI

struct HomeRootView: View {
    @ObservedObject private var language = AppLanguageManager.shared
    @EnvironmentObject private var homeCoordinator: HomeCoordinator
    @EnvironmentObject private var tabs: TabsCoordinator
    var offersTab = false
    var body: some View {
        NavigationStack(path: $homeCoordinator.path) {
            Group {
                if offersTab {
                    HomeSearchView(isTabRoot: true)
                        .logScreen("OffersView")
                } else {
                    HomeView()
                        .logScreen("HomeView")
                }
            }
            .navigationDestination(for: HomeRoute.self) { route in
                homeCoordinator.destination(for: route)
                    .toolbar(.hidden, for: .tabBar)
            }
        }
        .sheet(isPresented: $homeCoordinator.showsLogin) {
            HomeLoginSheet(hint: homeCoordinator.loginHint,
                           destination: homeCoordinator.loginRoute.map { .home($0) })
        }
        .environmentObject(homeCoordinator.model)
        .environmentObject(tabs.moreCoordinator.account.payments)
        .toolbar(homeCoordinator.path.isEmpty ? .visible : .hidden, for: .tabBar)
        .environment(\.locale, Locale(identifier: language.selectedLanguage))
        .environment(\.layoutDirection, language.layoutDirection)
        .id(language.selectedLanguage)
    }
}
