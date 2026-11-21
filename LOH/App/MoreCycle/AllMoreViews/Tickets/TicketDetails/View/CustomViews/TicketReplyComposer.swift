import SwiftUI

struct TicketReplyComposer: View {
    @Binding var text: String
    let canSend: Bool
    let sending: Bool
    let send: () -> Void

    var body: some View {
        HStack(alignment: .bottom, spacing: 12) {
            Button(action: send) {
                AccountFlowIcon(name: "Send", size: 20)
                    .frame(width: 44, height: 44)
                    .background(AppColor.action, in: Circle())
            }
            .buttonStyle(.plain)
            .disabled(!canSend)
            .accessibilityLabel("more.Send".localized)

            TextField("more.Write your reply…".localized, text: $text, axis: .vertical)
                .font(AppFont.regular(size: 14))
                .foregroundStyle(AppColor.text)
                .lineLimit(1...4)
                .disabled(sending)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .frame(minHeight: 50)
                .overlay {
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(AppColor.border)
                }
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 16)
        .frame(maxWidth: 600)
        .frame(maxWidth: .infinity)
        .background(AppColor.surface)
        .onChange(of: text) { value in
            text = String(value.prefix(5000))
        }
    }
}
