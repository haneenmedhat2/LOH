import SwiftUI

struct HomePaymentProcessingView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var tabs: TabsCoordinator
    @EnvironmentObject private var coordinator: HomeCoordinator
    @StateObject private var viewModel: HomePaymentProcessingViewModel

    init(viewModel: @autoclosure @escaping () -> HomePaymentProcessingViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel())
    }

    var body: some View {
        VStack(spacing: 0) {
            HomeCheckoutHeader(step: 2, processing: viewModel.error == nil)
            ScrollView(showsIndicators: false) {
                VStack(spacing: 12) {
                    if let error = viewModel.error {
                        failureCard(error)
                    } else {
                        processingCard
                    }
                    CardContainer {
                        VStack(spacing: 0) {
                            detail(homeText("merchant"), viewModel.order.offer.displayMerchant)
                            Divider()
                            detail(homeText("offerLabel"), viewModel.order.offer.displayTitle)
                            Divider()
                            detail(homeText("paymentMethod"), homeText(viewModel.order.paymentType.titleKey))
                            Divider()
                            detail(
                                homeText("amount"),
                                homeMoney(viewModel.order.pricing.total, currency: viewModel.order.offer.currency),
                                accent: true)
                        }
                    }
                    HomeCheckoutSecurityCard()
                }
                .padding(16)
                .frame(maxWidth: 600)
                .frame(maxWidth: .infinity)
            }
        }
        .modifier(
            HomeScreenStyle(
                title: homeText(viewModel.error == nil ? "processingTitle" : "checkoutFailedTitle"),
                bodyColor: AppColor.accountCanvas,
                navigationColor: AppColor.surface
            )
        )
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .tabBar)
        .task {
            await viewModel.submit(language: AppLanguageManager.shared.apiLanguage)
            if let receipt = viewModel.receipt {
                tabs.purchasesModel.reset()
                coordinator.finishCheckout(receipt)
            }
        }
        .logScreen("HomePaymentProcessingView")
    }

    private var processingCard: some View {
        CardContainer(padding: 24) {
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color(red: 252 / 255, green: 233 / 255, blue: 229 / 255))
                        .frame(width: 218, height: 218)
                    Image("lohCheckoutPhone")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 180, height: 180)
                    Image("lohCheckoutContactless")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 50)
                        .offset(x: 40, y: 60)
                }
                .frame(height: 230)
                .environment(\.layoutDirection, .leftToRight)
                HomeCheckoutProgress(size: 40)
                    .padding(.top, 12)
                Text(homeText("processingPayment"))
                    .font(AppFont.extraBold(size: 20))
                Text(homeText("processingHint"))
                    .font(AppFont.regular(size: 14))
                    .foregroundStyle(AppColor.secondaryText)
                Text(homeText("stayOnPage"))
                    .font(AppFont.bold(size: 13))
                    .foregroundStyle(AppColor.primary)
            }
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
        }
    }

    private func failureCard(_ error: String) -> some View {
        CardContainer(padding: 24) {
            VStack(spacing: 16) {
                Text(homeText("checkoutFailedTitle"))
                    .font(AppFont.bold(size: 20))
                Text(error)
                    .font(AppFont.regular(size: 14))
                    .foregroundStyle(AppColor.secondaryText)
                if viewModel.outcomeUnknown {
                    Text(homeText("checkoutUnknownHint"))
                        .font(AppFont.regular(size: 13))
                        .foregroundStyle(AppColor.secondaryText)
                    MainAppButton(
                        title: homeText("viewPurchases"),
                        action: {
                            tabs.purchasesModel.reset()
                            coordinator.reset()
                            tabs.select(.orders)
                        }, variant: .action)
                    Button(homeText("backHome")) { coordinator.reset() }
                        .font(AppFont.bold(size: 14))
                        .foregroundStyle(AppColor.primary)
                        .frame(minHeight: 44)
                } else {
                    MainAppButton(title: homeText("checkoutBackToPayment"), action: { dismiss() }, variant: .action)
                }
            }
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
        }
    }

    private func detail(_ title: String, _ value: String, accent: Bool = false) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(title)
                .foregroundStyle(AppColor.secondaryText)
            Spacer(minLength: 8)
            Text(value)
                .font(accent ? AppFont.bold(size: 14) : AppFont.regular(size: 14))
                .foregroundStyle(accent ? AppColor.primary : AppColor.text)
                .multilineTextAlignment(.trailing)
        }
        .font(AppFont.regular(size: 14))
        .padding(.vertical, 10)
    }
}
