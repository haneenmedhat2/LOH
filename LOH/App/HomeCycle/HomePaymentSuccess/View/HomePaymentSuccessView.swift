import SwiftUI

struct HomePaymentSuccessView: View {
    @EnvironmentObject private var coordinator: HomeCoordinator
    @EnvironmentObject private var tabs: TabsCoordinator
    let receipt: HomeCheckoutReceipt

    var body: some View {
        VStack(spacing: 0) {
            HomeCheckoutHeader(step: 3)
            ScrollView(showsIndicators: false) {
                VStack(spacing: 12) {
                    successCard
                    HomePaymentSuccessOfferCard(
                        receipt: receipt, purchase: displayedPurchase,
                        count: receipt.purchases.isEmpty ? receipt.quantity : receipt.purchases.count,
                        onShowCode: {
                            if let purchase = displayedPurchase {
                                coordinator.show(.purchaseCode(id: purchase.id, status: purchase.status))
                            } else {
                                coordinator.show(.qrCode(receipt))
                            }
                        }, onPurchases: showPurchases)
                    purchasesHint
                    MainAppButton(title: homeText("viewPurchases"), action: showPurchases, variant: .action, height: 56)
                    Button(homeText("backHome")) {
                        coordinator.reset()
                        tabs.select(.home)
                    }
                    .font(AppFont.bold(size: 14))
                    .foregroundStyle(AppColor.primary)
                    .frame(minHeight: 44)
                }
                .padding(16)
                .frame(maxWidth: 600)
                .frame(maxWidth: .infinity)
            }
        }
        .modifier(
            HomeScreenStyle(
                title: homeText("paymentSucceeded"), bodyColor: AppColor.accountCanvas,
                navigationColor: AppColor.surface
            )
        )
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .tabBar)
        .logScreen("HomePaymentSuccessView")
    }

    private var displayedPurchase: PurchaseDetail? {
        receipt.purchases.first(where: { $0.canShowCode(status: nil) }) ?? receipt.purchases.first
    }

    private var successCard: some View {
        CardContainer(padding: 24) {
            VStack(spacing: 0) {
                Image("lohCheckoutCelebration")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 160, height: 140)
                    .overlay {
                        Image("lohCheckoutSuccessBadge")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 96, height: 96)
                            .shadow(color: .black.opacity(0.15), radius: 5, y: 5)
                            .offset(x: -48, y: -49)
                    }
                    .environment(\.layoutDirection, .leftToRight)
                    .padding(.top, 8)
                    .padding(.bottom, 16)
                Text(homeText("offerReady"))
                    .font(AppFont.black(size: 24))
                Text(
                    receipt.isPreview
                        ? homeText("checkoutPreviewComplete")
                        : (receipt.result?.message ?? homeText("checkoutPaymentComplete"))
                )
                .font(AppFont.regular(size: 14))
                .foregroundStyle(AppColor.secondaryText)
                .padding(.top, 8)
            }
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
        }
    }

    private var purchasesHint: some View {
        HStack(spacing: 12) {
            Image("lohCheckoutPurchases")
                .resizable()
                .scaledToFit()
                .frame(width: 18, height: 18)
                .frame(width: 40, height: 40)
                .background(AppColor.primary, in: Circle())
            Text(homeText("checkoutPurchasesHint"))
                .font(AppFont.regular(size: 14))
                .lineSpacing(4)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .background(AppColor.accentSurface, in: RoundedRectangle(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(AppColor.primary.opacity(0.25))
        }
    }

    private func showPurchases() {
        tabs.purchasesModel.reset()
        coordinator.reset()
        tabs.select(.orders)
    }
}
