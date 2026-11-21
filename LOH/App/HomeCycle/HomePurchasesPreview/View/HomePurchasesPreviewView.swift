import SwiftUI

/// The purchases tab stays empty until a backend can issue a real voucher.
struct HomePurchasesPreviewView: View {
    @EnvironmentObject private var tabs: TabsCoordinator
    @State private var login = false
    private var signedIn: Bool { UserDefaults.isLogin }
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                HomeIcon.purchasesEmpty.image
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 350)
                    .frame(height: 176)
                Text(homeText(signedIn ? "noPurchases" : "purchasesWaiting"))
                    .font(AppFont.heading)
                Text(homeText(signedIn ? "noPurchasesHint" : "purchasesLoginHint"))
                    .font(AppFont.regular(size: 14))
                    .foregroundStyle(AppColor.secondaryText)
                    .multilineTextAlignment(.center)
                if !signedIn {
                    MainAppButton(
                        title: homeText("login"),
                        action: {
                            login = true
                        }, variant: .action)
                }
                MainAppButton(
                    title: homeText("browseOffers"),
                    action: {
                        tabs.selectedTab = .offers
                    }, variant: .outlined)
            }
            .padding(20)
            .padding(.top, 30)
        }
        .modifier(HomeScreenStyle(title: homeText("purchases")))
        .sheet(isPresented: $login) {
            HomeLoginSheet()
        }
    }
}
