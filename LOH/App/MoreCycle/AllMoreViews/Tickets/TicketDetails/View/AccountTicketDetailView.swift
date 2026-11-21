import SwiftUI

struct AccountTicketDetailView: View {
    let id: Int
    @EnvironmentObject private var account: TicketListViewModel
    @EnvironmentObject private var coordinator: MoreCoordinator
    @StateObject private var viewModel = TicketDetailsViewModel()
    @ObservedObject private var language = AppLanguageManager.shared
    private var ticket: AccountTicket? { viewModel.ticket }
    private var displayedReplies: [TicketReply] {
        if !viewModel.replies.isEmpty { return viewModel.replies }
        guard let ticket, !ticket.description.isEmpty else { return [] }
        return [TicketReply(id: 0, text: ticket.description, isSupport: false, date: ticket.createdAt)]
    }
    var body: some View {
        AccountPage(
            title: "more.Ticket details".localized, hidesTabBar: true, headerHeight: 60, contentSpacing: 16,
            onRefresh: { await viewModel.load(id: id, using: account, language: language.apiLanguage) }
        ) {
            if viewModel.loading && ticket == nil { BrandLoaderView(size: 56).frame(maxWidth: .infinity).padding(32) }
            if let error = viewModel.error {
                HomeAPIError(message: error) {
                    Task { await viewModel.load(id: id, using: account, language: language.apiLanguage) }
                }
            }
            if let sendError = viewModel.sendError {
                HomeAPIError(message: sendError) {
                    Task { await viewModel.send(id: id, using: account, language: language.apiLanguage) }
                }
            }
            if let ticket {
                CardContainer {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(alignment: .top) {
                            Text(ticket.title)
                                .font(AppFont.extraBold(size: 17))
                                .frame(maxWidth: .infinity, alignment: .leading)
                            AccountTicketStatus(status: ticket.status, statusText: ticket.statusText)
                        }
                        Button {
                            UIPasteboard.general.string = ticket.code
                        } label: {
                            HStack(spacing: 8) {
                                Text(ticket.code)
                                    .font(.system(size: 13))
                                    .foregroundStyle(AppColor.secondaryText)
                                AccountFlowIcon(name: "Copy", size: 14)
                            }
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("accountFlow.Copy reference".localized)
                        if let date = ticket.createdAt {
                            Text("accountFlow.Created".localized + " " + date)
                                .font(AppFont.regular(size: 12))
                                .foregroundStyle(AppColor.mutedText)
                        }
                        if let orderID = ticket.orderID {
                            relatedOrder(orderID)
                                .padding(.top, 8)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                Text("more.Conversation".localized)
                    .font(AppFont.bold(size: 14))
                VStack(spacing: 12) {
                    ForEach(displayedReplies) { reply in
                        TicketReplyRow(reply: reply, language: language.apiLanguage)
                    }
                    if displayedReplies.last?.isSupport == true {
                        Text("tickets.supportTeam".localized)
                            .font(AppFont.regular(size: 11))
                            .foregroundStyle(AppColor.mutedText)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
        }
        .task(id: language.apiLanguage) {
            await viewModel.load(id: id, using: account, language: language.apiLanguage)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if ticket != nil && viewModel.canReply {
                TicketReplyComposer(text: $viewModel.replyText, canSend: viewModel.canSend, sending: viewModel.sending) {
                    Task { await viewModel.send(id: id, using: account, language: language.apiLanguage) }
                }
            }
        }
    }

    private func relatedOrder(_ id: Int) -> some View {
        Button {
            coordinator.show(.purchaseDetail(id))
        } label: {
            HStack(spacing: 12) {
                AccountFlowIcon(name: "Order", size: 20)
                    .frame(width: 44, height: 44)
                    .background(AccountFlowColor.iconSurface, in: RoundedRectangle(cornerRadius: 14))
                VStack(alignment: .leading, spacing: 6) {
                    Text("accountFlow.Related order".localized)
                        .font(AppFont.regular(size: 12))
                        .foregroundStyle(AppColor.secondaryText)
                    Text(ticket?.order?.label ?? "#\(id)")
                        .font(AppFont.bold(size: 14))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: "chevron.forward")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppColor.primary)
                    .accessibilityHidden(true)
            }
            .padding(16)
            .background(AppColor.accountCanvas, in: RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }
}
