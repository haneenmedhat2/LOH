import SwiftUI

struct AccountNewTicketView: View {
    @EnvironmentObject private var account: TicketListViewModel
    @ObservedObject private var language = AppLanguageManager.shared
    @StateObject private var viewModel = NewTicketViewModel()
    var body: some View {
        Group {
            if let ticket = viewModel.createdTicket {
                AccountTicketSuccessView(ticket: ticket)
            } else {
                AccountPage(
                    title: "accountFlow.Create ticket".localized,
                    hidesTabBar: true, headerHeight: 60, contentSpacing: 16
                ) {
                    AccountFlowIntro(
                        title: "accountFlow.How can we help".localized, subtitle: "accountFlow.Ticket intro".localized,
                        icon: "SupportHero"
                    )
                    if let error = viewModel.error {
                        HomeAPIError(message: error) {
                            Task { await viewModel.loadTypes(using: account, language: language.apiLanguage) }
                        }
                    }
                    CardContainer {
                        VStack(alignment: .leading, spacing: 16) {
                            if !viewModel.loadingTypes && !viewModel.types.isEmpty {
                                AccountFlowSelect(
                                    title: "more.Issue type".localized,
                                    placeholder: "more.Select an issue type".localized,
                                    selection: $viewModel.form.category,
                                    options: viewModel.types.map { (String($0.id), $0.name) },
                                    icon: "Category", required: true)
                            } else if !viewModel.loadingTypes && viewModel.error == nil {
                                Text("tickets.noTypes".localized).foregroundStyle(AppColor.secondaryText)
                            }
                            AccountFlowSelect(
                                title: "accountFlow.Related order optional".localized,
                                placeholder: "tickets.selectOrder".localized,
                                selection: $viewModel.form.relatedOrder,
                                options: viewModel.orders.isEmpty ? [] :
                                    viewModel.orders.map { (String($0.id), $0.label) }
                                        + [("", "tickets.noRelatedOrder".localized)],
                                icon: "Order")
                            .disabled(viewModel.loadingOrders || viewModel.ordersError != nil)
                            .zIndex(10)
                            if let ordersError = viewModel.ordersError {
                                HomeAPIError(message: ordersError) {
                                    Task { await viewModel.loadOrders(using: account, language: language.apiLanguage) }
                                }
                            }
                            AccountFlowField(
                                title: "more.Ticket title".localized, text: $viewModel.form.title,
                                placeholder: "accountFlow.Ticket title placeholder".localized, height: 54)
                            AccountTextArea(
                                title: "more.Issue details".localized, text: $viewModel.form.details,
                                placeholder: "accountFlow.Describe issue".localized, required: true)
                        }
                    }
                    .disabled(viewModel.submitting)
                    trackingInformation
                }
                .task(id: language.apiLanguage) {
                    await viewModel.loadTypes(using: account, language: language.apiLanguage)
                }
                .task(id: language.apiLanguage) {
                    await viewModel.loadOrders(using: account, language: language.apiLanguage)
                }
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    VStack(spacing: 0) {
                        if viewModel.loadingTypes || viewModel.loadingOrders || viewModel.submitting {
                            BrandLoaderView(size: 36).padding(.top, 8)
                        }
                        AccountFooter(title: "more.Submit ticket".localized, enabled: viewModel.canSubmit) {
                            Task { await viewModel.submit(using: account, language: language.apiLanguage) }
                        }
                    }
                    .background(AppColor.surface)
                    .overlay(alignment: .top) {
                        AppColor.border.frame(height: 1)
                    }
                }
                .onChange(of: viewModel.form.title) { value in
                    viewModel.form.title = String(value.prefix(191))
                }
            }
        }
    }

    private var trackingInformation: some View {
        CardContainer {
            HStack(spacing: 12) {
                Image("lohShieldCheck")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                    .foregroundStyle(AppColor.primary)
                    .frame(width: 44, height: 44)
                    .background(AccountFlowColor.iconSurface, in: RoundedRectangle(cornerRadius: 16))
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 6) {
                    Text("accountFlow.Ticket tracking".localized)
                        .font(AppFont.bold(size: 14))
                    Text("accountFlow.Track ticket status".localized)
                        .font(AppFont.regular(size: 11))
                        .foregroundStyle(AppColor.secondaryText)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
