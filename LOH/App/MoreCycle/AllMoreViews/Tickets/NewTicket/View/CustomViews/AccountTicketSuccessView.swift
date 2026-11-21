import SwiftUI

struct AccountTicketSuccessView: View {
    let ticket: AccountTicket
    @EnvironmentObject private var coordinator: MoreCoordinator
    var body: some View {
        AccountFlowSuccess(
            title: "accountFlow.Ticket success".localized,
            subtitle: "accountFlow.Ticket success subtitle".localized, ticket: true
        ) {
            CardContainer {
                VStack(spacing: 0) {
                    AccountFlowReference(
                        title: "accountFlow.Ticket number".localized, reference: ticket.code, centered: true)
                    Divider()
                        .opacity(0.4)
                    AccountFlowSummaryRow(
                        title: "accountFlow.Follow up status".localized,
                        value: ticket.statusText ?? ticketStatus(ticket.status), icon: "Category")
                    Divider()
                        .opacity(0.4)
                    AccountFlowSummaryRow(
                        title: "accountFlow.Ticket tracking".localized, value: "more.My tickets".localized,
                        icon: "SuccessBell")
                }
            }
            MainAppButton(
                title: "more.View ticket".localized,
                action: {
                    coordinator.pop()
                    coordinator.show(.ticket(ticket.id))
                }, variant: .action, height: 56)
            MainAppButton(
                title: "accountFlow.Back to help".localized,
                action: {
                    coordinator.pop()
                }, variant: .outlined, height: 58)
        }
    }
}
