//
//  TabsCoordinator.swift
//  CTF
//
//  Created by Mohamed Hadwa on 17/11/2025.
//


// TabsCoordinator.swift
import Foundation

@MainActor
final class TabsCoordinator: ObservableObject {

    @Published var selectedTab: MainTab = .home

    let homeCoordinator: HomeCoordinator
    let offersCoordinator: HomeCoordinator
    let homeModel: HomeViewModel
    let notificationsModel = NotificationsViewModel()
    let purchasesModel = PurchasesViewModel()

    init() {
        let model = HomeViewModel()
        homeModel = model
        homeCoordinator = HomeCoordinator(model: model)
        offersCoordinator = HomeCoordinator(model: model)
    }
    var moreCoordinator = MoreCoordinator()

    

    func select(_ tab: MainTab) {
        selectedTab = tab
    }

    func resetAll() {
        homeCoordinator.showsLogin = false
        offersCoordinator.showsLogin = false
        moreCoordinator.showsLogin = false
        notificationsModel.resetSession()
        purchasesModel.reset()
        homeCoordinator.reset()
        offersCoordinator.reset()
        moreCoordinator.reset()
    }
}
