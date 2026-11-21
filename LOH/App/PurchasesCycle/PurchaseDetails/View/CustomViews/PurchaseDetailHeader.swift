import SwiftUI

struct PurchaseDetailHeader: View {
    let purchase: PurchaseDetail
    let status: PurchaseStatus?

    private var title: String {
        if let title = purchase.header?.title, !title.isEmpty { return title }
        switch status {
        case .used: return homeText("purchaseBannerUsed")
        case .expired: return homeText("purchaseBannerExpired")
        default: return homeText("purchaseBannerReady")
        }
    }

    private var subtitle: String {
        if let description = purchase.header?.description, !description.isEmpty { return description }
        switch status {
        case .ready: return homeText("purchaseReadyDescription")
        case .used: return homeFormat("purchaseUsedDescriptionFormat", purchase.store?.name ?? purchase.coupon.name)
        default: return homeText("codeUnavailable")
        }
    }

    private var date: String? {
        purchase.header?.dateText ?? (status == .expired ? purchase.expiresAt : purchase.usedAt)
    }

    var body: some View {
        CardContainer(
            padding: status == .ready ? 20 : 16,
            cornerRadius: 16,
            background: status == .used ? AppColor.successSurface : AppColor.surface
        ) {
            if status == .ready {
                readyHeader
            } else {
                HStack(alignment: .top, spacing: 12) {
                    statusIcon
                    VStack(alignment: .leading, spacing: 6) {
                        Text(title)
                            .font(AppFont.extraBold(size: 16))
                            .fixedSize(horizontal: false, vertical: true)
                        Text(subtitle)
                            .font(AppFont.regular(size: 13))
                            .foregroundStyle(status == .used ? AppColor.success : AppColor.secondaryText)
                            .lineSpacing(3)
                            .fixedSize(horizontal: false, vertical: true)
                        if let date, !date.isEmpty {
                            Text(date)
                                .font(AppFont.regular(size: 12))
                                .foregroundStyle(AppColor.mutedText)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    if let status {
                        Text(purchase.statusText ?? homeText(status.titleKey))
                            .font(AppFont.regular(size: 11))
                            .foregroundStyle(status == .used ? AppColor.success : AppColor.secondaryText)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(
                                status == .used ? AppColor.success.opacity(0.12) : AppColor.disabledSurface,
                                in: Capsule()
                            )
                            .fixedSize()
                    }
                }
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var readyHeader: some View {
        VStack(spacing: 12) {
            Image("lohPurchaseDetailReady")
                .resizable()
                .scaledToFit()
                .frame(width: 40, height: 40)
                .frame(width: 80, height: 80)
                .background(AppColor.primary.opacity(0.1), in: Circle())
                .accessibilityHidden(true)
            Text(title)
                .font(AppFont.extraBold(size: 20))
                .fixedSize(horizontal: false, vertical: true)
            Text(subtitle)
                .font(AppFont.regular(size: 14))
                .foregroundStyle(AppColor.secondaryText)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder private var statusIcon: some View {
        if status == .used {
            Image("lohPurchaseDetailCheck")
                .resizable()
                .scaledToFit()
                .frame(width: 28, height: 28)
                .frame(width: 56, height: 56)
                .background(AppColor.success, in: Circle())
                .accessibilityHidden(true)
        } else {
            Image("lohPurchaseDetailExpired")
                .resizable()
                .scaledToFit()
                .frame(width: 36, height: 36)
                .frame(width: 64, height: 64)
                .background(AppColor.disabledSurface, in: RoundedRectangle(cornerRadius: 16))
                .accessibilityHidden(true)
        }
    }
}
