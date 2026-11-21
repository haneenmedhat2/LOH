import SwiftUI

struct HomeOrderReviewView: View {
    @EnvironmentObject private var coordinator: HomeCoordinator
    @StateObject private var viewModel: HomeOrderReviewViewModel

    init(offer: HomeOffer) {
        _viewModel = StateObject(wrappedValue: HomeOrderReviewViewModel(offer: offer))
    }

    private var offer: HomeOffer { viewModel.offer }
    private var quantity: Int { viewModel.quantity }
    var body: some View {
        VStack(spacing: 0) {
            HomeCheckoutHeader(step: 1)
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    CardContainer(padding: 20, cornerRadius: 20, border: AppColor.border.opacity(0.5)) {
                        VStack(spacing: 0) {
                            HomeCheckoutOfferSummary(offer: offer, showsAvailability: true) {
                                coordinator.show(.merchant(offer))
                            }
                            HStack {
                                HStack(spacing: 0) {
                                    quantityButton(.plus, label: "increase", disabled: quantity == 10) {
                                        viewModel.increaseQuantity()
                                    }
                                    Text(homeNumber(quantity))
                                        .font(AppFont.bold(size: 16))
                                        .frame(minWidth: 32)
                                    quantityButton(.minus, label: "decrease", disabled: quantity == 1) {
                                        viewModel.decreaseQuantity()
                                    }
                                }
                                .background(AppColor.surface, in: RoundedRectangle(cornerRadius: 12))
                                .overlay {
                                    RoundedRectangle(cornerRadius: 12)
                                        .strokeBorder(AppColor.border, lineWidth: 1)
                                }
                                Spacer()
                                Text(homeMoney(viewModel.pricing.subtotal, currency: offer.currency))
                                    .font(AppFont.black(size: 20))
                                    .foregroundStyle(AppColor.primary)
                            }
                            .padding(12)
                            .background(AppColor.accountCanvas, in: RoundedRectangle(cornerRadius: 14))
                            .padding(.top, 16)
                        }
                    }
                    CardContainer(padding: 20, cornerRadius: 20, border: AppColor.border.opacity(0.5)) {
                        VStack(alignment: .leading, spacing: 0) {
                            Text(homeText("priceDetails"))
                                .font(AppFont.bold(size: 17))
                                .frame(minHeight: 23)
                            priceRow("offerPrice", viewModel.pricing.subtotal)
                                .padding(.top, 12)
                            priceRow("serviceFee", viewModel.pricing.serviceFee)
                                .padding(.top, 12)
                            AppColor.border.opacity(0.5)
                                .frame(height: 1)
                                .padding(.top, 12)
                            priceRow("total", viewModel.pricing.total, total: true)
                                .padding(.top, 12)
                            Text(homeText("vatIncluded"))
                                .font(AppFont.regular(size: 11))
                                .foregroundStyle(AppColor.mutedText)
                                .frame(minHeight: 17)
                                .padding(.top, 4)
                        }
                    }
                    CardContainer(padding: 20, cornerRadius: 20, border: AppColor.border.opacity(0.5)) {
                        HStack(spacing: 14) {
                            HomeIcon.orderClock.view(28)
                                .frame(width: 44, height: 44)
                                .background(AppColor.accountCanvas, in: RoundedRectangle(cornerRadius: 12))
                            VStack(alignment: .leading, spacing: 4) {
                                Text(homeText("whenUse"))
                                    .font(AppFont.bold(size: 14))
                                Text(homeText("codeAfterPayment"))
                                    .font(AppFont.regular(size: 12))
                                    .foregroundStyle(AppColor.secondaryText)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
                .padding(16)
                .frame(maxWidth: 600)
                .frame(maxWidth: .infinity)
            }
        }
        .background(
            AppColor.accountCanvas
                .ignoresSafeArea()
        )
        .foregroundStyle(AppColor.text)
        .appNavigationBar(homeText("reviewOrder"))
        .safeAreaInset(edge: .bottom) {
            HomeCheckoutBar(total: viewModel.pricing.total, title: "continuePayment", currency: offer.currency) {
                coordinator.show(.payment(offer, quantity))
            }
            .disabled(!viewModel.canContinue)
        }
        .toolbar(.hidden, for: .tabBar)
    }
    private func quantityButton(_ icon: HomeIcon, label: String, disabled: Bool, action: @escaping () -> Void)
        -> some View
    {
        Button(action: action) {
            icon.view(16)
                .frame(width: 36, height: 36)
        }
        .disabled(disabled)
        .opacity(disabled ? 0.35 : 1)
        .accessibilityLabel(homeText(label))
    }
    private func priceRow(_ title: String, _ amount: Double, total: Bool = false) -> some View {
        HStack {
            Text(homeText(title))
                .foregroundStyle(total ? AppColor.text : AppColor.secondaryText)
            Spacer()
            Text(homeMoney(amount, currency: offer.currency))
                .foregroundStyle(total ? AppColor.primary : AppColor.text)
        }
        .font(total ? AppFont.bold(size: 16) : AppFont.regular(size: 14))
        .frame(minHeight: total ? 24 : 21)
    }
}
