import Foundation

// Navigation collaborators only; the app/auth coordinator implementations are production code.
enum MainTab { case home, offers, orders, more }
enum HomeRoute: Equatable { case offer(Int), favorites, notifications }
enum MoreCoordinatorRoute: Equatable { case tickets, payments }
enum AuthRoute: Hashable { case register, selectCities, selectInterests, location, accountSuccess, verification(phone: String, countryCode: String) }
enum AuthModalRoute { case test }
struct UserRegisterModel {}
struct APIUser {}
struct APIEnvelope<T> { let key: String }
enum AuthPreviewSession { static var user: APIUser? }
extension UserDefaults { static var isLogin = false; static var isFirstTime = false }
extension Notification.Name {
    static let lohSessionExpired = Notification.Name("test.sessionExpired")
    static let userUnauthorized = Notification.Name("test.unauthorized")
}
@MainActor final class AuthSession {
    static let shared = AuthSession()
    enum Stage { case signedOut, cities, interests, authenticated }
    var stage = Stage.signedOut
    var token: String?
    var isGuestBrowsing = false
    var isAuthenticated: Bool { stage == .authenticated && token != nil }
    func restore() async throws {}
    func clear() { token = nil; stage = .signedOut; isGuestBrowsing = false }
    func continueAsGuest() { clear(); isGuestBrowsing = true }
    func logout() async throws { clear() }
    func authenticate() { token = "test-token"; stage = .authenticated; isGuestBrowsing = false }
}
@MainActor final class ResettableModel {
    func resetSession() {}
    func reset() {}
}
@MainActor final class HomeCoordinator {
    var path: [HomeRoute] = []
    func show(_ route: HomeRoute) { path.append(route) }
}
@MainActor final class MoreCoordinator {
    let account = ResettableModel()
    var path: [MoreCoordinatorRoute] = []
    func show(_ route: MoreCoordinatorRoute) { path.append(route) }
}
enum OrderType { case goods, surfaces, people }
enum OrdersRoute { case orderType(OrderType) }
@MainActor final class TabsCoordinator {
    var selectedTab = MainTab.home
    var pendingOrdersRoute: OrdersRoute?
    let homeModel = ResettableModel()
    let notificationsModel = ResettableModel()
    let purchasesModel = ResettableModel()
    let moreCoordinator = MoreCoordinator()
    let homeCoordinator = HomeCoordinator()
    func resetAll() { homeCoordinator.path = []; moreCoordinator.path = [] }
}

@main struct GuestNavigationTests {
    @MainActor static func main() {
        let destinations: [GuestDestination] = [.tab(.orders), .tab(.more), .tab(.offers),
            .home(.offer(197)), .home(.favorites), .home(.notifications), .account(.tickets)]
        for destination in destinations {
            AuthSession.shared.continueAsGuest()
            let app = AppCoordinator()
            app.tabsCoordinator.selectedTab = .orders
            app.beginAuthentication(destination: destination)
            precondition(app.root == .auth)
            app.authCoordinator.continueAsGuest()
            precondition(app.root == .mainTabs)
            precondition(app.tabsCoordinator.selectedTab == .home, "Continuing as guest must always open Home")
            precondition(app.tabsCoordinator.homeCoordinator.path.isEmpty && app.tabsCoordinator.moreCoordinator.path.isEmpty)
            // The discarded destination must not leak into a later, unrelated login.
            app.showAuth()
            AuthSession.shared.authenticate()
            app.authCoordinator.loginSucceeded()
            precondition(app.tabsCoordinator.selectedTab == .home)
            precondition(app.tabsCoordinator.homeCoordinator.path.isEmpty && app.tabsCoordinator.moreCoordinator.path.isEmpty)
        }
        AuthSession.shared.continueAsGuest()
        let app = AppCoordinator()
        app.beginAuthentication(destination: .tab(.orders))
        AuthSession.shared.authenticate()
        app.authCoordinator.loginSucceeded()
        precondition(app.tabsCoordinator.selectedTab == .orders, "A successful login should still resume purchases")
        app.beginAuthentication(destination: .home(.offer(197)))
        app.authCoordinator.loginSucceeded()
        precondition(app.tabsCoordinator.selectedTab == .home && app.tabsCoordinator.homeCoordinator.path == [.offer(197)])
        app.beginAuthentication(destination: .account(.tickets))
        app.authCoordinator.loginSucceeded()
        precondition(app.tabsCoordinator.selectedTab == .more && app.tabsCoordinator.moreCoordinator.path == [.tickets])
        app.beginAuthentication(register: true, destination: .tab(.orders))
        precondition(app.authCoordinator.path == [.register])
        app.authCoordinator.onFinishAuth?()
        precondition(app.tabsCoordinator.selectedTab == .orders, "Registration completion should resume purchases")
        app.beginAuthentication(register: true, destination: .tab(.more))
        app.authCoordinator.continueAsGuest()
        precondition(app.tabsCoordinator.selectedTab == .home)
        print("PASS: guest entry always opens Home, stale destinations are discarded, login and registration resume intended screens")
    }
}
