//
//  NewSwiftUIBaseApp.swift
//  NewSwiftUIBase
//
//  Created by Mohamed Hadwa on 22/07/2025.
//

import SwiftUI
import IQKeyboardManagerSwift
import IQKeyboardToolbarManager
import IQKeyboardToolbar
import GoogleMaps

@main
struct NewSwiftUIBaseApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @ObservedObject private var language = AppLanguageManager.shared
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    init() {
        setupKeyboardManager()
        setupNavigationBarAppearance()
        if AppServices.externalSDKsEnabled {
            GMSServices.provideAPIKey(UserDefaults.googleMapKey)
        }

    }

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .environment(\.locale, Locale(identifier: language.selectedLanguage))
                .environment(\.layoutDirection, language.layoutDirection)
                .preferredColorScheme(.light)
                .onChange(of: scenePhase) { phase in
                    guard phase == .active else {
                        return
                    }
                    language.refreshFromSystem()
                    setupKeyboardManager()
                }
                .onAppear {
                    language.refreshFromSystem()
                    if let token = UserDefaults.pushNotificationToken {
                        print("✅ [App] Current saved FCM Token: \(token)")
                    } else {
                        print("ℹ️ [FCM] No saved token yet; waiting for APNs registration")
                    }
                }
        }
    }

    private func setupNavigationBarAppearance() {
        let appearance = UINavigationBarAppearance()

        appearance.configureWithOpaqueBackground()

        appearance.backgroundColor = UIColor(AppColor.surface)

        appearance.shadowColor = .clear
        appearance.setBackIndicatorImage(
            AppNavigationStyle.backIndicator,
            transitionMaskImage: AppNavigationStyle.backIndicator)

        let backButtonAppearance = UIBarButtonItemAppearance()
        let backTitleAttributes: [NSAttributedString.Key: Any] = [
            .font: AppFont.uiFont(.regular, size: 17, relativeTo: .body)
        ]
        backButtonAppearance.normal.titleTextAttributes = backTitleAttributes
        backButtonAppearance.highlighted.titleTextAttributes = backTitleAttributes
        appearance.backButtonAppearance = backButtonAppearance

        appearance.titleTextAttributes = [
            .font: AppNavigationStyle.titleFont,
            .foregroundColor: UIColor(AppColor.text)
        ]

        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().compactScrollEdgeAppearance = appearance

        UINavigationBar.appearance().tintColor = UIColor(AppColor.primary)
        UIBarButtonItem.appearance().tintColor = UIColor(AppColor.primary)

        // Keep layout behind the bar available to photo screens. Each screen's
        // toolbar appearance still controls whether its background is opaque.
        UINavigationBar.appearance().isTranslucent = true
    }

    private func setupKeyboardManager() {
        let keyboardManager = IQKeyboardManager.shared
        keyboardManager.isEnabled = true
        keyboardManager.resignOnTouchOutside = true
        let toolbarManager = IQKeyboardToolbarManager.shared
        toolbarManager.isEnabled = true

        toolbarManager.toolbarConfiguration.manageBehavior = .byPosition

        let doneConfig = IQBarButtonItemConfiguration(title: "Done".localized)
        toolbarManager.toolbarConfiguration.doneBarButtonConfiguration = doneConfig

        toolbarManager.toolbarConfiguration.tintColor = .primaryMain
    }
}
