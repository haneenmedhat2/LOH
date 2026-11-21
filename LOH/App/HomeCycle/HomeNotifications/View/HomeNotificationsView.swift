import SwiftUI

struct HomeNotificationsView: View {
    @EnvironmentObject private var coordinator: HomeCoordinator
    var body: some View {
        NotificationsView(onOpenOffer: {
            coordinator.show(.offerID(String($0)))
        })
    }
}
