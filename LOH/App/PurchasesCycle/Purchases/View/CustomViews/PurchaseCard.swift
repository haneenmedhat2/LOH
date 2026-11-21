import SwiftUI

struct PurchaseCard: View {
    let coupon: PurchaseCoupon
    let fallbackStatus: PurchaseStatus?
    let open: (Bool) -> Void
    @State private var referenceCopied = false
    @ScaledMetric(relativeTo: .body) private var imageSize = 110.0

    private var status: PurchaseStatus? { coupon.status ?? fallbackStatus }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            summary
            VStack(spacing: 8) {
                if coupon.canOpenCode(status: fallbackStatus) {
                    Button {
                        open(true)
                    } label: {
                        HStack(spacing: 8) {
                            Image("lohPurchaseShowCode")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 16, height: 16)
                            Text(homeText("purchaseShowCode"))
                        }
                    }
                    .buttonStyle(
                        MainButtonStyle(variant: .action, height: 47, cornerRadius: 12, font: AppFont.bold(size: 15))
                    )
                }
                Button {
                    open(false)
                } label: {
                    Text(homeText(status == .ready ? "purchaseDetails" : "viewDetails"))
                }
                .buttonStyle(
                    MainButtonStyle(variant: .outlined, height: 49, cornerRadius: 12, font: AppFont.bold(size: 15))
                )
                if let rating = coupon.rating, rating.displayValue != nil {
                    PurchaseRatingRow(rating: rating)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 4)
                }
            }
        }
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(AppColor.surface)
                .shadow(color: .black.opacity(0.08), radius: 2, y: 1)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(AppColor.border.opacity(0.45), lineWidth: 0.5)
        }
    }

    private var summary: some View {
        HStack(alignment: .top, spacing: 12) {
            HomePhoto(asset: coupon.image ?? "")
                .frame(width: min(imageSize, 130), height: min(imageSize, 130))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay {
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(AppColor.border.opacity(0.55), lineWidth: 0.5)
                }
            VStack(alignment: .leading, spacing: 7) {
                Text(coupon.merchant)
                    .font(AppFont.bold(size: 16))
                    .foregroundStyle(AppColor.text)
                Text(coupon.name)
                    .font(AppFont.bold(size: 14))
                    .foregroundStyle(AppColor.text)
                    .fixedSize(horizontal: false, vertical: true)
                if let status {
                    PurchaseStatusBadge(status: status, title: coupon.statusText)
                }
                if !coupon.location.isEmpty {
                    PurchaseLocationLabel(address: coupon.location)
                }
                if let number = coupon.couponNumber, !number.isEmpty {
                    referenceButton(number, label: homeText("copyCouponNumber"))
                } else if let reference = coupon.reference, !reference.isEmpty {
                    referenceButton(reference, label: homeText("copyOrderNumber"))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .multilineTextAlignment(.leading)
        }
    }

    private func referenceButton(_ reference: String, label: String) -> some View {
        Button {
            UIPasteboard.general.string = reference
            referenceCopied = true
        } label: {
            HStack(spacing: 4) {
                Image("lohPurchaseReferenceCopy")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 12, height: 12)
                Text(referenceCopied ? homeText("codeCopied") : reference)
                    .font(AppFont.regular(size: 12))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .foregroundStyle(AppColor.mutedText)
            .padding(.vertical, 5)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
        .accessibilityValue(referenceCopied ? homeText("codeCopied") : reference)
    }
}

struct PurchaseStatusBadge: View {
    let status: PurchaseStatus
    var title: String? = nil

    private var color: Color {
        switch status {
        case .ready, .used: return AppColor.success
        case .expired: return AppColor.secondaryText
        }
    }

    private var text: String {
        guard let title, !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return homeText(status.titleKey)
        }
        return title
    }

    var body: some View {
        Text(text)
            .font(AppFont.medium(size: 12))
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 5)
            .background(color, in: Capsule())
    }
}

func purchasePrice(_ value: Double, currency: String?) -> String {
    guard let currency, !currency.isEmpty else {
        return homeMoney(value)
    }
    let amount = value.formatted(
        .number.locale(Locale(identifier: AppLanguageManager.shared.selectedLanguage))
            .precision(.fractionLength(0...2)))
    return amount + " " + currency
}
