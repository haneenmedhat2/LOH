import SwiftUI

struct HomePaymentView: View {
    @EnvironmentObject private var coordinator: HomeCoordinator
    @EnvironmentObject private var tabs: TabsCoordinator
    @EnvironmentObject private var payments: PaymentCardViewModel
    @StateObject private var viewModel: HomePaymentViewModel
    @State private var addCard = false

    init(offer: HomeOffer, quantity: Int) {
        _viewModel = StateObject(wrappedValue: HomePaymentViewModel(offer: offer, quantity: quantity))
    }

    var body: some View {
        VStack(spacing: 0) {
            HomeCheckoutHeader(step: 2)
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    HomeCheckoutSecurityCard()
                    paymentMethods
                    savedCards
                    HomePaymentOfferCard(
                        offer: viewModel.offer,
                        quantity: viewModel.quantity,
                        total: viewModel.pricing.total
                    ) {
                        coordinator.show(.merchant(viewModel.offer))
                    }
                }
                .padding(16)
                .frame(maxWidth: 600)
                .frame(maxWidth: .infinity)
            }
        }
        .modifier(
            HomeScreenStyle(
                title: homeText("paymentMethod"), bodyColor: AppColor.accountCanvas, navigationColor: AppColor.surface
            )
        )
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 8) {
                Button {
                    if let order = viewModel.makeOrder() {
                        coordinator.show(.paymentProcessing(order))
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image("lohCheckoutButtonLock")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 16, height: 16)
                            .accessibilityHidden(true)
                        Text(
                            homeFormat(
                                "confirmPaymentFormat",
                                homeMoney(viewModel.pricing.total, currency: viewModel.offer.currency)
                            )
                        )
                        .multilineTextAlignment(.center)
                    }
                }
                .buttonStyle(MainButtonStyle(variant: .action, height: 56, font: AppFont.bold(size: 16)))
                .disabled(!viewModel.pricing.isValid || viewModel.isContinuing)
                Text(homeText("checkoutConfirmHint"))
                    .font(AppFont.regular(size: 11))
                    .foregroundStyle(AppColor.mutedText)
                    .multilineTextAlignment(.center)
            }
            .padding(16)
            .background(AppColor.surface)
        }
        .toolbar(.hidden, for: .tabBar)
        .task { await payments.loadCards() }
        .onAppear { viewModel.resumeSelection() }
        .sheet(isPresented: $addCard, onDismiss: { Task { await payments.loadCards() } }) {
            NavigationStack {
                AddPaymentCardView()
                    .modifier(AccountRequestState())
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("cancel_title".localized) { addCard = false }
                        }
                    }
            }
            .modifier(MoreAccountEnvironment(account: tabs.moreCoordinator.account))
        }
        .alert(
            homeText("paymentMethod"),
            isPresented: Binding(
                get: { viewModel.error != nil },
                set: { if !$0 { viewModel.error = nil } }
            )
        ) {
            Button(homeText("ok"), role: .cancel) { viewModel.error = nil }
        } message: {
            Text(viewModel.error ?? "")
        }
    }

    private var paymentMethods: some View {
        CardContainer(padding: 20, cornerRadius: 20, border: AppColor.border.opacity(0.5)) {
            VStack(alignment: .leading, spacing: 16) {
                Text(homeText("choosePayment"))
                    .font(AppFont.bold(size: 17))
                VStack(spacing: 10) {
                    ForEach(HomePaymentMethod.allCases) { method in
                        HomePaymentMethodRow(
                            method: method,
                            isSelected: viewModel.method == method && viewModel.selectedCardID == nil
                        ) {
                            viewModel.select(method)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var savedCards: some View {
        CardContainer(padding: 20, cornerRadius: 20, border: AppColor.border.opacity(0.5)) {
            VStack(alignment: .leading, spacing: 16) {
                Text("more.Saved cards".localized)
                    .font(AppFont.bold(size: 17))
                Text(homeText("checkoutSavedCardsHint"))
                    .font(AppFont.regular(size: 12))
                    .foregroundStyle(AppColor.mutedText)
                if let error = payments.cardsError {
                    HomeAPIError(message: error) {
                        Task { await payments.loadCards() }
                    }
                } else if !payments.cardsLoaded {
                    BrandLoaderView(size: 36)
                        .frame(maxWidth: .infinity, minHeight: 44)
                } else if payments.cards.isEmpty {
                    Text("more.No saved cards".localized)
                        .font(AppFont.regular(size: 13))
                        .foregroundStyle(AppColor.secondaryText)
                } else {
                    VStack(spacing: 0) {
                        ForEach(payments.cards) { card in
                            HomeCheckoutSavedCardRow(card: card, isSelected: viewModel.selectedCardID == card.id) {
                                viewModel.selectCard(card)
                            }
                            Divider()
                        }
                    }
                }
                Button {
                    addCard = true
                } label: {
                    HStack {
                        HomeIcon.plus.view(16)
                        Spacer()
                        Text("more.Add a new card".localized)
                            .font(AppFont.medium(size: 14))
                    }
                    .frame(minHeight: 33)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .foregroundStyle(AppColor.primary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
