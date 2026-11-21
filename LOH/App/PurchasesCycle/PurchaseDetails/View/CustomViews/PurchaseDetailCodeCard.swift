import SwiftUI

struct PurchaseDetailCodeCard: View {
    let code: String?
    let status: PurchaseStatus?
    let statusText: String?
    let isInactive: Bool
    var retry: (() -> Void)?

    private var message: String {
        if let statusText { return statusText }
        switch status {
        case .used: return homeText("purchaseCodeUsed")
        case .expired: return homeText("purchaseCodeExpired")
        default: return homeText(isInactive ? "codeUnavailable" : "purchaseCodeMissing")
        }
    }

    var body: some View {
        CardContainer(padding: 16, cornerRadius: 16) {
            VStack(spacing: 12) {
                Text(homeText("usageCode"))
                    .font(AppFont.bold(size: 14))
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text(status == .used ? (code ?? "••••• •••••") : "••••• •••••")
                    .font(AppFont.bold(size: 22))
                    .tracking(3)
                    .foregroundStyle(AppColor.mutedText)
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .overlay {
                        if status == .used && code != nil {
                            AppColor.mutedText
                                .frame(height: 1)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 16)
                    .frame(maxWidth: .infinity, minHeight: 58)
                    .overlay {
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(AppColor.mutedText.opacity(0.5), lineWidth: 2)
                    }
                    .environment(\.layoutDirection, .leftToRight)
                    .accessibilityLabel(message)
                HStack(spacing: 8) {
                    if status == .used {
                        Image("lohPurchaseCodeReady")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 14, height: 14)
                    }
                    Text(message)
                        .font(AppFont.regular(size: 12))
                        .foregroundStyle(status == .used ? AppColor.success : AppColor.mutedText)
                        .multilineTextAlignment(.center)
                }
                if let retry {
                    Button("api.retry".localized, action: retry)
                        .font(AppFont.medium(size: 13))
                        .foregroundStyle(AppColor.primary)
                        .frame(minHeight: 44)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
}
