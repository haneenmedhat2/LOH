import SwiftUI

struct AccountTicketsView: View {
    @EnvironmentObject private var account: TicketListViewModel
    @EnvironmentObject private var coordinator: MoreCoordinator
    @ObservedObject private var language = AppLanguageManager.shared
    private var tickets: [AccountTicket] { account.filteredTickets }
    var body: some View {
        AccountPage(
            title: "more.My tickets".localized, headerHeight: 60,
            topContent: AnyView(filters),
            onRefresh: { await account.reload(language: language.apiLanguage) }
        ) {
            if account.loading && !account.loaded {
                BrandLoaderView(size: 56).frame(maxWidth: .infinity).padding(32)
            }
            if let error = account.error {
                HomeAPIError(message: error) {
                    Task { await account.loadMore(language: language.apiLanguage) }
                }
            }
            if account.loaded && account.tickets.isEmpty {
                emptyState
            } else if account.loaded {
                Text(
                    String(
                        format: "accountFlow.Ticket count".localized,
                        account.filter.search.isEmpty ? account.total : tickets.count)
                )
                .font(AppFont.regular(size: 12))
                .foregroundStyle(AppColor.secondaryText)
                .padding(.vertical, 4)
                if tickets.isEmpty {
                    Text("accountFlow.No matching tickets".localized)
                        .foregroundStyle(AppColor.secondaryText)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                }
                ForEach(tickets) { ticket in
                    Button {
                        coordinator.show(.ticket(ticket.id))
                    } label: {
                        AccountTicketCard(ticket: ticket)
                    }
                    .buttonStyle(.plain)
                }
                if account.hasMore {
                    Button("api.loadMore".localized) {
                        Task { await account.loadMore(language: language.apiLanguage) }
                    }
                    .disabled(account.loading)
                    .frame(maxWidth: .infinity)
                    .padding()
                }
                if account.loading { BrandLoaderView(size: 56).frame(maxWidth: .infinity) }
            }
        }
        .task(id: "\(language.apiLanguage):\(account.filter.status)") {
            await account.reload(language: language.apiLanguage)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if !account.tickets.isEmpty {
                VStack(spacing: 8) {
                    createButton
                    faqButton
                }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 2)
                    .background(AppColor.accountCanvas)
            }
        }
    }
    private var filters: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                ForEach(["all", "open", "in_progress", "closed"], id: \.self) { value in
                    Button {
                        account.filter.status = value
                    } label: {
                        Text(value == "all" ? "more.All".localized : ticketStatus(value))
                        .font(AppFont.regular(size: 12))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .frame(maxWidth: .infinity, minHeight: 40)
                        .foregroundStyle(account.filter.status == value ? AppColor.primary : AppColor.secondaryText)
                        .background(
                            account.filter.status == value ? AppColor.accentSurface : AppColor.surface,
                            in: RoundedRectangle(cornerRadius: 12)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(account.filter.status == value ? AppColor.primary : AppColor.border))
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(account.filter.status == value ? .isSelected : [])
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            if !account.tickets.isEmpty {
                Divider()
                    .opacity(0.4)
                HStack(spacing: 12) {
                    AccountFlowIcon(name: "Search", size: 16)
                    TextField("more.Search tickets".localized, text: $account.filter.search)
                        .font(AppFont.regular(size: 14))
                        .accessibilityLabel("more.Search tickets".localized)
                }
                .padding(.horizontal, 16)
                .frame(height: 46)
                .background(AppColor.accountCanvas, in: RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
        }
        .background(AppColor.surface)
    }
    private var createButton: some View {
        MainAppButton(
            title: "accountFlow.Create ticket".localized,
            action: {
                coordinator.show(.newTicket)
            },
            variant: .action, icon: Image("lohFlowPlus"), height: 56, iconSize: 18)
    }
    private var emptyState: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(AppColor.accentSurface)
                    .frame(width: 180, height: 180)
                AccountFlowIcon(name: "EmptyTickets", size: 200)
            }
            .frame(height: 220)
            .padding(.top, 12)
            Text("accountFlow.No tickets yet".localized)
                .font(AppFont.extraBold(size: 24))
            Text("accountFlow.Empty tickets message".localized)
                .font(AppFont.regular(size: 14))
                .foregroundStyle(AppColor.secondaryText)
                .multilineTextAlignment(.center)
            createButton
                .padding(.top, 8)
            faqButton
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
    }
    private var faqButton: some View {
        Button("faq.browse".localized) {
            coordinator.show(.faqs)
        }
        .font(AppFont.medium(size: 14))
        .foregroundStyle(AppColor.primary)
    }
}
