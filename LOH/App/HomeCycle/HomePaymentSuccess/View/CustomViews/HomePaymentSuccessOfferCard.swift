import SwiftUI

struct HomePaymentSuccessOfferCard: View {
    let receipt: HomeCheckoutReceipt
    let purchase: PurchaseDetail?
    let count: Int
    let onShowCode: () -> Void
    let onPurchases: () -> Void

    var body: some View {
        CardContainer(padding: 16, cornerRadius: 16) {
            VStack(spacing: 16) {
                offerSummary
                VStack(spacing: 12) {
                    if canShowCode {
                        if let code {
                            codePanel(code)
                        } else {
                            Text(homeText("purchasePromoHintReady"))
                                .font(AppFont.regular(size: 13))
                                .foregroundStyle(AppColor.secondaryText)
                                .multilineTextAlignment(.center)
                        }
                        codeButton(title: "showFullCode", action: onShowCode)
                    } else {
                        unavailableCodePanel
                        codeButton(title: "checkoutOpenCodes", action: onPurchases)
                    }
                }
            }
        }
    }

    private var offerSummary: some View {
        HStack(alignment: .top, spacing: 12) {
            HomePhoto(asset: image)
                .frame(width: 96, height: 96)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay {
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(AppColor.border.opacity(0.6))
                }
            VStack(alignment: .leading, spacing: 0) {
                if let merchant, !merchant.isEmpty {
                    Text(merchant)
                        .font(AppFont.medium(size: 13))
                        .foregroundStyle(AppColor.primary)
                        .frame(minHeight: 24, alignment: .leading)
                }
                Text(purchase?.coupon.name ?? receipt.offer.displayTitle)
                    .font(AppFont.extraBold(size: 17))
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 4)
                    .frame(minHeight: 30, alignment: .leading)
                if count > 1 {
                    Text(homeFormat("checkoutQuantityFormat", homeNumber(count)))
                        .font(AppFont.medium(size: 12))
                        .foregroundStyle(AppColor.secondaryText)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(AppColor.accountCanvas, in: Capsule())
                        .padding(.top, 6)
                }
                if let amount {
                    Text(homeText(receipt.isPreview ? "amountPaidPreview" : "checkoutAmountPaid"))
                        .font(AppFont.bold(size: 14))
                        .foregroundStyle(AppColor.primary)
                        .padding(.top, 4)
                        .frame(minHeight: 25, alignment: .leading)
                    Text(homeMoney(amount, currency: currency))
                        .font(AppFont.black(size: 20))
                        .foregroundStyle(AppColor.primary)
                        .frame(minHeight: 30, alignment: .leading)
                }
                if let address, !address.isEmpty {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Image("lohCheckoutLocation")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 12, height: 12)
                            .accessibilityHidden(true)
                        Text(address)
                            .font(AppFont.regular(size: 12))
                            .foregroundStyle(AppColor.secondaryText)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.top, 4)
                    .frame(minHeight: 22, alignment: .leading)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var unavailableCodePanel: some View {
        VStack(spacing: 8) {
            Text(homeText("usageCode"))
                .font(AppFont.medium(size: 12))
                .foregroundStyle(AppColor.success)
            Text(unavailableCodeMessage)
                .font(AppFont.regular(size: 13))
                .foregroundStyle(AppColor.secondaryText)
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(AppColor.codeSurface, in: RoundedRectangle(cornerRadius: 16))
    }

    private var image: String {
        guard let purchase else { return receipt.offer.asset }
        return purchase.coupon.image ?? ""
    }

    private var merchant: String? {
        guard let purchase else { return receipt.offer.displayMerchant }
        return purchase.store?.name
    }

    private var address: String? {
        guard let purchase else { return receipt.offer.checkoutAddress }
        return purchase.store?.address
    }

    private var amount: Double? {
        guard let purchase else { return receipt.total }
        return purchase.order?.paidAmount
    }

    private var currency: String? {
        guard let purchase else { return receipt.offer.currency }
        return purchase.order?.currency
    }

    private var canShowCode: Bool {
        guard let purchase else { return receipt.code != nil }
        return purchase.canShowCode(status: nil)
    }

    private var code: String? {
        guard canShowCode else { return nil }
        return purchase?.code ?? receipt.code
    }

    private var unavailableCodeMessage: String {
        if let purchase,
            purchase.voucherCode?.isActive == false || purchase.status == .used || purchase.status == .expired
        {
            return purchase.voucherCode?.statusText ?? homeText("codeUnavailable")
        }
        return homeText("checkoutCodeInPurchases")
    }

    private func codePanel(_ code: String) -> some View {
        VStack(spacing: 8) {
            Text(homeText("usageCode"))
                .font(AppFont.medium(size: 12))
                .foregroundStyle(AppColor.success)
                .frame(minHeight: 18)
            HStack {
                Text(code)
                    .font(AppFont.bold(size: 20))
                    .tracking(2)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .environment(\.layoutDirection, .leftToRight)
                Spacer()
                CheckoutCopyButton(code: code, compact: true)
            }
            .padding(.horizontal, 12)
            .frame(minHeight: 48)
            .background(AppColor.surface, in: RoundedRectangle(cornerRadius: 12))
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(AppColor.codeBorder)
            }
            Text(homeText(receipt.isPreview ? "demoCodeHint" : "purchasePromoHintReady"))
                .font(AppFont.regular(size: 11))
                .foregroundStyle(AppColor.secondaryText)
                .multilineTextAlignment(.center)
                .frame(minHeight: 17)
        }
        .padding(12)
        .background(AppColor.codeSurface, in: RoundedRectangle(cornerRadius: 16))
    }

    private func codeButton(title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image("lohCheckoutQRIcon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 18, height: 18)
                Text(homeText(title))
                    .font(AppFont.medium(size: 14))
            }
            .foregroundStyle(AppColor.success)
            .frame(maxWidth: .infinity, minHeight: 47)
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(AppColor.codeBorder)
            }
        }
        .buttonStyle(.plain)
    }
}
