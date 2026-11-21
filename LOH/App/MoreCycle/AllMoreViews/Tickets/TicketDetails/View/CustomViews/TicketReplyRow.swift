import SwiftUI

struct TicketReplyRow: View {
    let reply: TicketReply
    let language: String

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            AccountFlowIcon(name: reply.isSupport ? "SupportAvatar" : "Avatar", size: 16)
                .frame(width: 32, height: 32)
                .background(
                    reply.isSupport ? AccountFlowColor.supportSurface : AppColor.disabledSurface,
                    in: Circle())
            VStack(alignment: .leading, spacing: 10) {
                Text(reply.text)
                    .font(AppFont.regular(size: 14))
                    .foregroundStyle(AppColor.text)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
                    .textSelection(.enabled)
                if let time = reply.timeText(language: language) {
                    Text(time)
                        .font(AppFont.regular(size: 11))
                        .foregroundStyle(AppColor.mutedText)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(reply.isSupport ? AppColor.surface : AccountFlowColor.iconSurface)
            Spacer(minLength: 0)
                .frame(width: 32)
        }
    }
}

#Preview("Ticket replies — Arabic") {
    VStack(spacing: 12) {
        TicketReplyRow(
            reply: TicketReply(id: 1, text: "السلام عليكم، تظهر لي رسالة خطأ عند محاولة الدفع بالبطاقة.",
                               isSupport: false, date: "2026-07-15 09:41:00"), language: "ar")
        TicketReplyRow(
            reply: TicketReply(id: 2, text: "وعليكم السلام عبدالرازق، نعتذر لك. جاري التحقق من عملية الدفع وسنوافيك بالتحديث هنا.",
                               isSupport: true, date: "2026-07-15 09:48:00"), language: "ar")
        TicketReplyRow(
            reply: TicketReply(id: 3, text: "تأكدنا أن العملية لم تُخصم من بطاقتك. جرب المحاولة مرة أخرى أو اختر طريقة دفع مختلفة.",
                               isSupport: true, date: "2026-07-15 10:12:00"), language: "ar")
    }
    .padding(16)
    .background(AppColor.accountCanvas)
    .environment(\.layoutDirection, .rightToLeft)
}
