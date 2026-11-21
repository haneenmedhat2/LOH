import SwiftUI

struct CheckoutCopyButton: View {
    let code: String
    var compact = false
    @State private var copied = false
    var body: some View {
        Button {
            UIPasteboard.general.string = code
            copied = true
        } label: {
            HStack(spacing: compact ? 6 : 8) {
                Image(compact ? "lohCheckoutCopy" : "lohCheckoutFullCopy")
                    .resizable()
                    .scaledToFit()
                    .frame(width: compact ? 14 : 16, height: compact ? 14 : 16)
                Text(homeText(copied ? "codeCopied" : compact ? "copy" : "copyCode"))
                    .font(AppFont.medium(size: compact ? 13 : 14))
            }
            .foregroundStyle(compact ? AppColor.success : AppColor.text)
            .frame(maxWidth: compact ? nil : .infinity, minHeight: compact ? 24 : 46)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(compact ? .clear : AppColor.border))
        }
        .buttonStyle(.plain)
    }
}
