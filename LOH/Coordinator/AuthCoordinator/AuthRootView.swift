//
//  AuthRootView.swift
//  CTF
//
//  Created by Mohamed Hadwa on 16/11/2025.
//

import SwiftUI

struct AuthRootView: View {
    @EnvironmentObject var authCoordinator: AuthCoordinator
    @ObservedObject private var language = AppLanguageManager.shared

    var body: some View {
        NavigationStack(path: $authCoordinator.path) {
            Group {
                if authCoordinator.showsOnboarding {
                    OnboardingView(onFinish: authCoordinator.completeOnboarding)
                        .logScreen("OnboardingView")
                } else {
                    LoginView()
                        .logScreen("LoginView")
                }
            }
            .navigationDestination(for: AuthRoute.self) { route in
                switch route {
                case .selectCities:
                    AuthCitySelectionView()
                case .selectInterests:
                    AuthPreferencesView(cities: false)
                case .passwordRecovery:
                    PasswordRecoveryView(onReturnToLogin: authCoordinator.returnToLogin)
                case .register:
                    CompleteRegisterDataView()
                        .logScreen("CompleteRegisterDataView")
                case .terms:
                    AccountDocumentView(document: .terms)
                        .logScreen("AccountDocumentView")
                case .location:
                    AuthLocationView()
                case .accountSuccess:
                    AccountSuccessView()
                        .logScreen("AccountSuccessView")
                case let .verification(phone, countryCode):
                    VerificationCodeView(
                        phone: phone,
                        countryCode: countryCode, type: .loginAsUser,
                        registration: authCoordinator.registrationDraft
                    )
                    .logScreen("VerificationCodeView")
                case let .completeRegisterData(phone, countryCode):
                    CompleteRegisterDataView(phone: phone, countryCode: countryCode, phoneAlreadyVerified: true)
                        .logScreen("CompleteRegisterDataView")
                }
            }
        }
        .environment(\.locale, Locale(identifier: language.selectedLanguage))
        .environment(\.layoutDirection, language.layoutDirection)
        .sheet(item: $authCoordinator.modalRoute) { modal in
            switch modal {
            case .language:
                LanguageSheetView {
                    authCoordinator.dismissModal()
                }
                .presentationDetents([.height(350)])
                .presentationDragIndicator(.visible)
                .interactiveDismissDisabled(false)
                .presentationCornerRadius(28)
            }
        }
    }
}
