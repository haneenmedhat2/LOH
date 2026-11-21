import SwiftUI

func ticketStatus(_ status: String) -> String {
    switch status {
    case "closed": return "more.Closed".localized
    case "in_progress": return "more.In progress".localized
    default: return "more.Open".localized
    }
}

struct AccountTicketStatus: View {
    let status: String
    var statusText: String? = nil
    private var color: Color {
        status == "closed" ? AppColor.secondaryText : status == "in_progress" ? Color.blue : AppColor.success
    }
    var body: some View {
        Text(statusText ?? ticketStatus(status))
            .font(AppFont.medium(size: 11))
            .foregroundStyle(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                color
                    .opacity(0.1), in: Capsule())
    }
}

struct AccountTicketCard: View {
    let ticket: AccountTicket
    var body: some View {
        CardContainer {
            HStack(alignment: .top, spacing: 12) {
                Group {
                    if ticket.category == "refund" {
                        Text("SR")
                            .font(.system(size: 9))
                            .foregroundStyle(AppColor.primary)
                    } else {
                        AccountFlowIcon(
                            name: ticket.category == "payment"
                                ? "Payment" : ticket.category == "offer" ? "Redeem" : "Person", size: 16)
                    }
                }
                .frame(width: 32, height: 32)
                .background(AccountFlowColor.iconSurface, in: RoundedRectangle(cornerRadius: 12))
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .top) {
                        Text(ticket.title)
                            .font(AppFont.bold(size: 14))
                            .frame(maxWidth: .infinity, alignment: .leading)
                        AccountFlowIcon(name: "Forward", size: 16)
                    }
                    Text(ticket.code)
                        .font(.system(size: 11))
                        .foregroundStyle(AppColor.mutedText)
                    Text(ticket.description)
                        .font(AppFont.regular(size: 12))
                        .foregroundStyle(AppColor.secondaryText)
                        .lineLimit(1)
                    HStack {
                        AccountTicketStatus(status: ticket.status, statusText: ticket.statusText)
                        Spacer(minLength: 4)
                        if let date = ticket.updatedAt ?? ticket.createdAt {
                            Text(date)
                                .font(AppFont.regular(size: 10))
                                .foregroundStyle(AppColor.mutedText)
                        }
                    }
                    .padding(.top, 4)
                }
            }
        }
    }
}
