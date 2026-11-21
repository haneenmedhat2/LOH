import SwiftUI

struct PaymentCardView: View {
    @EnvironmentObject private var requests: AccountRequestController
    @EnvironmentObject private var account: PaymentCardViewModel
    @EnvironmentObject private var coordinator: MoreCoordinator
    @State private var selectedCard: AccountCard?
    @State private var pendingDialog: PaymentCardDialogRoute?
    @State private var dialog: PaymentCardDialogRoute?

    var body: some View {
        AccountPage(title: "more.Payment methods".localized, headerHeight: 60, contentTopPadding: 16,
                    onRefresh: { await account.loadCards() }) {
            Button {
                coordinator.show(.addCard)
            } label: {
                CardContainer {
                    HStack(spacing: 12) {
                        PaymentCardsIllustration()
                            .frame(width: 80, height: 65)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("more.Add a new card".localized)
                                .font(AppFont.button)
                            Text("more.Manage your cards for faster, easier checkout".localized)
                                .font(AppFont.regular(size: 13))
                                .foregroundStyle(AppColor.secondaryText)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        ProfileDirectionalIcon(asset: .paymentForward, size: 20)
                    }
                }
            }
            .buttonStyle(.plain)
            CardContainer(padding: 16, cornerRadius: 16) {
                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("more.Saved cards".localized)
                            .font(AppFont.extraBold(size: 16))
                        Text("more.Manage your cards and choose a default.".localized)
                            .font(AppFont.regular(size: 12))
                            .foregroundStyle(AppColor.secondaryText)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    if let error = account.cardsError {
                        Text(error)
                            .font(AppFont.body)
                            .foregroundStyle(AppColor.error)
                        Button("accountAPI.retry".localized) {
                            Task {
                                await account.loadCards()
                            }
                        }
                    }
                    if !account.cardsLoaded && account.cardsError == nil {
                        BrandLoaderView(size: 56)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 24)
                    } else if account.cardsLoaded && account.cards.isEmpty && account.cardsError == nil {
                        VStack(spacing: 8) {
                            profileIcon(.paymentFormCard, size: 16)
                            Text("more.No saved cards".localized)
                                .font(AppFont.bold(size: 15))
                            Text("accountAPI.addCardHint".localized)
                                .font(AppFont.regular(size: 12))
                                .foregroundStyle(AppColor.secondaryText)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)
                    } else {
                        VStack(spacing: 8) {
                            ForEach(account.cards) { card in
                                PaymentSavedCardRow(card: card) {
                                    selectedCard = card
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            CardContainer {
                HStack(spacing: 16) {
                    profileIcon(.paymentSecurity, size: 36)
                        .frame(width: 64, height: 64)
                        .background(Color(red: 232 / 255, green: 65 / 255, blue: 33 / 255).opacity(0.06), in: Circle())
                    VStack(alignment: .leading, spacing: 4) {
                        Text("more.Secure payments".localized)
                            .font(AppFont.bold(size: 16))
                        Text("accountAPI.cardsHint".localized)
                            .font(AppFont.regular(size: 12))
                            .foregroundStyle(AppColor.secondaryText)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .task {
            await account.loadCards()
        }
        .sheet(
            item: $selectedCard,
            onDismiss: {
                if let pendingDialog {
                    self.pendingDialog = nil
                    showDialog(pendingDialog)
                }
            }
        ) { card in
            PaymentCardActionsSheet(
                card: card,
                makeDefault: {
                    Task { @MainActor in
                        if await account.setDefaultCard(card) {
                            selectedCard = nil
                        }
                    }
                },
                rename: {
                    pendingDialog = .rename(card)
                    selectedCard = nil
                },
                delete: {
                    pendingDialog = .delete(card)
                    selectedCard = nil
                }
            )
            .modifier(AccountRequestState())
            .presentationDetents([.height(340)])
            .presentationDragIndicator(.visible)
            .presentationBackground(AppColor.surface)
            .presentationCornerRadius(24)
        }
        .fullScreenCover(item: $dialog) { route in
            PaymentCardDialog(
                route: route,
                cancel: {
                    showDialog(nil)
                },
                confirm: { name in
                    Task {
                        let saved: Bool
                        switch route {
                        case .delete(let card): saved = await account.removeCard(card.id)
                        case .rename(let card): saved = await account.renameCard(card.id, name: name)
                        }
                        if saved {
                            showDialog(nil)
                        }
                    }
                }
            )
            .modifier(AccountRequestState())
            .presentationBackground(.clear)
        }
    }

    private func showDialog(_ route: PaymentCardDialogRoute?) {
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            dialog = route
        }
    }
}
