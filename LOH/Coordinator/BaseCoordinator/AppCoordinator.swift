//
//  AppCoordinator.swift
//  CTF
//
//  Created by Mohamed Hadwa on 17/11/2025.
//


import SwiftUI
import Combine

enum GuestDestination {
    case tab(MainTab)
    case home(HomeRoute)
    case account(MoreCoordinatorRoute)
}

@MainActor
final class AppCoordinator: ObservableObject {
    
    @Published var root: AppRoot = .splash
    @Published var restorationError: String?
    private var restoringSession = false
    private var pendingGuestDestination: GuestDestination?
    private var pendingDeepLink: HomeRoute?
    private var cancellables = Set<AnyCancellable>()
    
    var isLoggedIn: Bool {
        get { UserDefaults.isLogin }
        set { UserDefaults.isLogin = newValue }
    }
    
    let authCoordinator = AuthCoordinator()
    let tabsCoordinator = TabsCoordinator()
    
    init() {
        bindChildCoordinators()
        observeUnauthorized()
        NotificationCenter.default.publisher(for: .lohSessionExpired)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] note in
                guard let token = note.object as? String, token == UserDefaults.accessToken else { return }
                self?.authCoordinator.clearSession()
                self?.clearSessionUI()
                self?.showAuth()
            }.store(in: &cancellables)
    }
    
    private func bindChildCoordinators() {
        authCoordinator.onLoginSuccess = { [weak self] isGuest in
            guard let self else { return }
            
            if !isGuest {
                self.isLoggedIn = true
            }
            self.showMainTabs()
        }

        authCoordinator.onFinishAuth = { [weak self] in
            self?.showMainTabs()
        }
    }

    // MARK: - Root switches
    
    private func observeUnauthorized() {
        NotificationCenter.default.publisher(for: .userUnauthorized)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.authCoordinator.clearSession()
                self?.clearSessionUI()
                self?.showAuth()
            }
            .store(in: &cancellables)
    }
    func decideInitialRoot() {
        guard root == .splash, !restoringSession else { return }
        restoringSession = true; restorationError = nil
        Task {
            defer { restoringSession = false }
            do {
                authCoordinator.start(showOnboarding: UserDefaults.accessToken == nil && UserDefaults.isFirstTime)
                guard let token = UserDefaults.accessToken else {
                    if UserDefaults.isGuestBrowsing { showMainTabs() } else { root = .auth }
                    return
                }
                try await authCoordinator.restoreSession()
                guard root == .splash, UserDefaults.accessToken == token else { return }
                root = .auth
                authCoordinator.resumeSession()
            } catch {
                guard root == .splash else { return }
                restorationError = error.localizedDescription
            }
        }
    }
    func clearSessionData() {
        pendingGuestDestination = nil
        tabsCoordinator.homeModel.resetSession()
        tabsCoordinator.moreCoordinator.account.resetSession()
        tabsCoordinator.notificationsModel.resetSession()
        tabsCoordinator.purchasesModel.reset()
    }
    func clearSessionUI() {
        clearSessionData()
        tabsCoordinator.resetAll()
    }
    func signOut() async throws {
        if let token = UserDefaults.accessToken {
            try await DefaultResponseHandler().perform(
                AuthEndpoints.logout(token: token), language: AppLanguageManager.shared.apiLanguage)
        }
        authCoordinator.clearSession()
        clearSessionUI()
        showAuth()
    }
    func forgetSession() {
        authCoordinator.clearSession()
        clearSessionUI()
        showAuth()
    }

    func showSplash() {
        root = .splash
    }

    func openDeepLink(_ route: HomeRoute) {
        guard root == .mainTabs else {
            pendingDeepLink = route
            // A public offer detail can be opened without an account. If the
            // link arrives before session restoration, continue as a guest so
            // it does not get stranded on the authentication screen.
            if UserDefaults.accessToken == nil {
                UserDefaults.isGuestBrowsing = true
                if root == .auth { showMainTabs() }
            }
            return
        }
        tabsCoordinator.selectedTab = .home
        tabsCoordinator.homeCoordinator.showsLogin = false
        tabsCoordinator.homeCoordinator.replace(with: route)
    }
    
    func beginAuthentication(register: Bool = false, destination: GuestDestination? = nil) {
        pendingGuestDestination = destination ?? .tab(.home)
        showAuth()
        if register { authCoordinator.push(.register) }
    }

    func showAuth() {
        if AuthPreviewSession.user == nil { tabsCoordinator.homeModel.resetSession() }
        isLoggedIn = false
        authCoordinator.start()
        root = .auth
    }
    
    func showMainTabs() {
        tabsCoordinator.homeModel.resetSession()
        tabsCoordinator.moreCoordinator.account.resetSession()
        tabsCoordinator.resetAll()
        root = .mainTabs
        tabsCoordinator.selectedTab = .home
        if let route = pendingDeepLink {
            pendingDeepLink = nil
            pendingGuestDestination = nil
            tabsCoordinator.homeCoordinator.show(route)
            return
        }
        let destination = isLoggedIn ? pendingGuestDestination : nil
        pendingGuestDestination = nil
        switch destination {
        case .tab(let tab): tabsCoordinator.selectedTab = tab
        case .home(let route):
            tabsCoordinator.homeCoordinator.show(route)
        case .account(let route):
            tabsCoordinator.selectedTab = .more
            tabsCoordinator.moreCoordinator.show(route)
        case nil: break
        }
        
    }
    
    private func handleLoginSuccess() {
        isLoggedIn = true
        showMainTabs()
    }
}
