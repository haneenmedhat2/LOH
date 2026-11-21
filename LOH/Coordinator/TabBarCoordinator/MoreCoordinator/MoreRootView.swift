//
//  MoreRootView.swift
//  CTF
//
//  Created by Mohamed Hadwa on 26/11/2025.
//

import SwiftUI

struct MoreRootView: View {
    @EnvironmentObject var appCoordinator: AppCoordinator
    @EnvironmentObject var moreCoordinator: MoreCoordinator

    @ObservedObject private var language = AppLanguageManager.shared

    var body: some View {
        NavigationStack(path: $moreCoordinator.path) {
            MoreScreen()
                .logScreen("MoreScreen")
                .navigationDestination(for: MoreCoordinatorRoute.self) { route in
                    moreCoordinator.destination(for: route)
                        .toolbar(.hidden, for: .tabBar)
                }
        }
        .sheet(isPresented: $moreCoordinator.showsLogin) {
            HomeLoginSheet(hint: "loginAccountHint",
                           destination: moreCoordinator.loginRoute.map { .account($0) })
        }
        .environmentObject(appCoordinator)
        .environmentObject(moreCoordinator)
        .toolbar(moreCoordinator.path.isEmpty ? .visible : .hidden, for: .tabBar)
        .modifier(AccountRequestState())
        .modifier(MoreAccountEnvironment(account: moreCoordinator.account))
        .environment(\.layoutDirection, language.layoutDirection)
        .environment(\.locale, Locale(identifier: language.selectedLanguage))
        .sheet(item: $moreCoordinator.modalRoute) { modal in
            switch modal {
            case .changeLanguage:
                LanguageSheetView {
                    moreCoordinator.dismissModal()
                }
                .presentationDetents([.height(350)])
                .presentationDragIndicator(.visible)
                .interactiveDismissDisabled(false)
                .presentationCornerRadius(28)
            }
        }
    }
}
