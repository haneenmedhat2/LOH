//
//  RootCoordinatorView.swift
//  CTF
//
//  Created by Mohamed Hadwa on 16/11/2025.
//

import SwiftUI

struct RootCoordinatorView: View {

    @EnvironmentObject var appCoordinator: AppCoordinator
    @StateObject private var notificationsCoordinator = NotificationsCoordinator()
    @State private var pendingPush: PushPayload?
    @State private var accountNoticeTitle: String?
    @State private var accountNotice: String?
    @State private var showingAccountNotice = false

    var body: some View {
        ZStack {
            switch appCoordinator.root {
            case .splash:
                SplashView()
                    .logScreen("SplashView")
                    .environmentObject(appCoordinator)

            case .auth:
                AuthRootView()
                    .environmentObject(appCoordinator.authCoordinator)

            case .mainTabs:
                MainTabsRootView()
                    .environmentObject(appCoordinator.tabsCoordinator)
                    .environmentObject(appCoordinator.tabsCoordinator.homeCoordinator)
                    .environmentObject(appCoordinator.tabsCoordinator.moreCoordinator)
                    .environmentObject(notificationsCoordinator)
            }

            NavigationStack(path: $notificationsCoordinator.path) {
                Color.clear
                    .navigationDestination(for: NotificationsRoute.self) { route in
                        notificationsCoordinator.destination(for: route)
                    }
            }
            .opacity(notificationsCoordinator.path.isEmpty ? 0 : 1)
        }
        .environmentObject(notificationsCoordinator)
        .environmentObject(appCoordinator.tabsCoordinator.notificationsModel)
        .onReceive(NotificationCenter.default.publisher(for: .notificationsShouldRefresh)) { _ in
            Task {
                await appCoordinator.tabsCoordinator.notificationsModel.refreshCount(
                    language: AppLanguageManager.currentLanguage())
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .pushDidTap)) { note in
            guard let payload = note.object as? PushPayload else {
                return
            }
            AppDelegate.pendingTappedPayload = nil
            handlePushTap(payload)
        }
        .onReceive(NotificationCenter.default.publisher(for: .pushDidReceiveForeground)) { note in
            guard let payload = note.object as? PushPayload,
                  payload.destination == .blocked || payload.destination == .deleted
            else { return }
            handlePushTap(payload)
        }
        .onAppear {
            if let payload = AppDelegate.pendingTappedPayload {
                AppDelegate.pendingTappedPayload = nil
                handlePushTap(payload)
            }
        }
        .onChange(of: appCoordinator.root) { root in
            guard root == .mainTabs, let payload = pendingPush else { return }
            pendingPush = nil
            handlePushTap(payload)
        }
        .alert(accountNoticeTitle ?? "notifications_title".localized, isPresented: $showingAccountNotice) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(accountNotice ?? "")
        }
    }

    private func handlePushTap(_ payload: PushPayload) {
        guard appCoordinator.root == .mainTabs else {
            pendingPush = payload
            return
        }
        if payload.destination == .blocked || payload.destination == .deleted {
            accountNoticeTitle = payload.title
            accountNotice = payload.body ?? ""
            appCoordinator.forgetSession()
            notificationsCoordinator.reset()
            showingAccountNotice = true
            return
        }
        guard appCoordinator.isLoggedIn else { return }
        switch payload.destination {
        case .offer(let id):
            notificationsCoordinator.reset()
            appCoordinator.tabsCoordinator.selectedTab = .home
            appCoordinator.tabsCoordinator.homeCoordinator.show(.offerID(String(id)))
        case .purchasedOffer(let id):
            notificationsCoordinator.reset()
            appCoordinator.tabsCoordinator.selectedTab = .more
            appCoordinator.tabsCoordinator.moreCoordinator.show(.purchaseDetail(id))
        case .order:
            // The purchase detail endpoint takes a purchased voucher ID, not
            // order_id. Open the orders tab until an order detail route exists.
            notificationsCoordinator.reset()
            appCoordinator.tabsCoordinator.selectedTab = .orders
        case .complaint:
            notificationsCoordinator.reset()
            appCoordinator.tabsCoordinator.selectedTab = .more
            appCoordinator.tabsCoordinator.moreCoordinator.show(.tickets)
        case .supportRoom(_, let ticketID):
            notificationsCoordinator.reset()
            appCoordinator.tabsCoordinator.selectedTab = .more
            if let ticketID {
                appCoordinator.tabsCoordinator.moreCoordinator.show(.ticket(ticketID))
            } else {
                appCoordinator.tabsCoordinator.moreCoordinator.show(.tickets)
            }
        case .blocked, .deleted:
            break
        case .cart, .settlements, .notifications:
            openNotifications()
        }
    }

    private func openNotifications() {
        notificationsCoordinator.replace(with: .notifications)
    }

}
