//
//  AuthVerificationCodeViewModel.swift
//  CTF
//
//  Created by Mohamed Hadwa on 23/11/2025.
//

import SwiftUI

struct AppRootView: View {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var appCoordinator = AppCoordinator()
    @StateObject private var alertCenter = AlertCenter.shared
    @StateObject private var maintenance = MaintenanceViewModel.shared
    @StateObject private var appUpdate = AppUpdateViewModel.shared

    var body: some View {
        RootCoordinatorView()
            .font(AppFont.body)
            .foregroundStyle(AppColor.text)
            .tint(AppColor.primary)
            .background(
                AppColor.canvas
                    .ignoresSafeArea()
            )
            .environmentObject(appCoordinator)
            .environmentObject(alertCenter)
            .safeAreaInset(edge: .top, spacing: 0) {
                if let alert = alertCenter.currentAlert {
                    AppAlertBanner(alert: alert) {
                        alertCenter.dismiss()
                    }
                    .transition(
                        .move(edge: .top)
                            .combined(with: .opacity)
                    )
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                }
            }
            .background(MaintenancePresentation(viewModel: maintenance))
            .background(AppUpdatePresentation(viewModel: appUpdate))
            .task { await appUpdate.checkForUpdate() }
            .onChange(of: scenePhase) { phase in
                if phase == .active { Task { await appUpdate.checkForUpdate() } }
            }
            .onOpenURL { url in
                guard let route = AppDeepLink.route(for: url) else { return }
                appCoordinator.openDeepLink(route)
            }
    }
}
