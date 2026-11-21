//
//  AppRoot.swift
//  CTF
//
//  Created by Mohamed Hadwa on 16/11/2025.
//

import Foundation


final class AuthCoordinator: BaseCoordinator<AuthRoute> {
    enum Stage: Equatable { case signedOut, cities, interests, authenticated }
    @Published private(set) var showsOnboarding = false
    @Published private(set) var stage: Stage = .signedOut
    var registrationDraft: UserRegisterModel?

    var finishingRegistration = false

    @MainActor func handle(_ response: APIEnvelope<APIUser>, phone: String, countryCode: String, registration: Bool = false) {
        finishingRegistration = finishingRegistration || registration
        if response.key == "needActive" {
            push(.verification(phone: phone, countryCode: countryCode))
        } else if registration {
            stage = .authenticated
            save(response.data)
            showAccountSuccess()
        } else {
            stage = response.key == "selectCity" ? .cities : response.key == "selectInterests" ? .interests : .authenticated
            save(response.data)
            resumeSession()
        }
    }

    @MainActor func resumeSession() {
        switch stage {
        case .cities: replace(with: .selectCities)
        case .interests: replace(with: .selectInterests)
        case .authenticated:
            if finishingRegistration { showAccountSuccess() } else { loginSucceeded() }
        case .signedOut: returnToLogin()
        }
    }

    @MainActor func restoreSession() async throws {
        guard let token = UserDefaults.accessToken else { stage = .signedOut; return }
        let response: APIEnvelope<APIUser> = try await DefaultResponseHandler().send(
            AuthEndpoints.profile(token: token), language: AppLanguageManager.shared.apiLanguage)
        guard UserDefaults.accessToken == token else { throw CancellationError() }
        if response.key == "needActive" {
            clearSession()
            return
        }
        guard response.data != nil else { throw APIError.invalidResponse }
        stage = response.key == "selectCity" || response.data?.cities.isEmpty == true ? .cities
            : response.key == "selectInterests" ? .interests : .authenticated
        save(response.data)
    }

    @MainActor func refreshSessionAfterSelection() async throws {
        try await restoreSession()
        resumeSession()
    }

    private func save(_ user: APIUser?) {
        guard let user else { return }
        if let token = user.token, !token.isEmpty { UserDefaults.accessToken = token }
        UserDefaults.save(user)
        UserDefaults.isLogin = stage == .authenticated
        UserDefaults.isGuestBrowsing = false
    }

    func clearSession() {
        UserDefaults.clearAuthentication()
        AuthPreviewSession.user = nil
        stage = .signedOut
    }

    func returnToLogin() {
        finishingRegistration = false
        registrationDraft = nil
        reset()
    }

    func showLocation() { replace(with: .location) }

    func showCitySelection() {
        finishingRegistration = false
        replace(with: .selectCities)
    }

    func showAccountSuccess() {
        registrationDraft = nil
        replace(with: .accountSuccess)
    }

    func start(showOnboarding: Bool = false) {
        if UserDefaults.accessToken == nil { stage = .signedOut }
        registrationDraft = nil
        finishingRegistration = false
        reset()
        modalRoute = nil
        showsOnboarding = showOnboarding
    }

    func completeOnboarding() {
        UserDefaults.isFirstTime = false
        showsOnboarding = false
    }

    var onLoginSuccess: ((Bool) -> Void)?
    @Published var modalRoute: AuthModalRoute?
    var onFinishAuth: (() -> Void)?
    
    func loginSucceeded(isGuest: Bool = false) {
        registrationDraft = nil
        print("🟢 AuthCoordinator.loginSucceeded(isGuest: \(isGuest)) fired")
        onLoginSuccess?(isGuest)
        reset()
        modalRoute = nil
    }
    func present(_ modal: AuthModalRoute) {
        modalRoute = modal
    }
    
    func dismissModal() {
        modalRoute = nil
    }
    
    @MainActor func continueAsGuest() {
        clearSession()
        UserDefaults.isGuestBrowsing = true
        onFinishAuth?()
    }
}
