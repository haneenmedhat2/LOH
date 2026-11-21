import SwiftUI

struct HomePaymentOfferCard: View {
    let offer: HomeOffer
    let quantity: Int
    let total: Double
    let onMerchant: () -> Void
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 16) {
                Text(homeText("checkoutOrderSummary"))
                    .font(AppFont.bold(size: 17))
                    .foregroundStyle(AppColor.text)
                offerLayout {
                    HomePhoto(asset: offer.asset)
                        .frame(width: 108, height: 108)
                        .background(AppColor.canvas)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                        .overlay {
                            RoundedRectangle(cornerRadius: 18)
                                .strokeBorder(AppColor.border.opacity(0.65), lineWidth: 1)
                        }
                    offerInformation
                }
            }
            .padding(18)
            totalSection
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .overlay {
            RoundedRectangle(cornerRadius: 22)
                .strokeBorder(AppColor.border.opacity(0.65), lineWidth: 1)
        }
    }

    private var offerLayout: AnyLayout {
        if dynamicTypeSize.isAccessibilitySize {
            return AnyLayout(VStackLayout(alignment: .leading, spacing: 14))
        }
        return AnyLayout(HStackLayout(alignment: .top, spacing: 14))
    }

    private var offerInformation: some View {
        VStack(alignment: .leading, spacing: 8) {
            merchant
            Text(offer.displayTitle)
                .font(AppFont.bold(size: 18))
                .foregroundStyle(AppColor.text)
                .fixedSize(horizontal: false, vertical: true)
            if let address = offer.checkoutAddress {
                HStack(alignment: .top, spacing: 5) {
                    HomeIcon.pin.view(13)
                    Text(address)
                        .font(AppFont.regular(size: 12))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .foregroundStyle(AppColor.secondaryText)
            }
            Text(homeFormat("checkoutQuantityFormat", homeNumber(quantity)))
                .font(AppFont.medium(size: 12))
                .foregroundStyle(AppColor.secondaryText)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(AppColor.accountCanvas, in: Capsule())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder private var merchant: some View {
        if !offer.isRemote || (offer.store?.id ?? 0) > 0 {
            Button(action: onMerchant) {
                HStack(spacing: 6) {
                    Text(offer.displayMerchant)
                        .font(AppFont.medium(size: 13))
                        .fixedSize(horizontal: false, vertical: true)
                    Image(systemName: "chevron.forward")
                        .font(.system(size: 10, weight: .semibold))
                }
                .foregroundStyle(AppColor.primary)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        } else {
            Text(offer.displayMerchant)
                .font(AppFont.medium(size: 13))
                .foregroundStyle(AppColor.secondaryText)
        }
    }

    private var totalSection: some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(homeText("total"))
                    .font(AppFont.bold(size: 14))
                    .foregroundStyle(AppColor.text)
                Text(homeText("vatIncluded"))
                    .font(AppFont.regular(size: 11))
                    .foregroundStyle(AppColor.secondaryText)
            }
            Spacer(minLength: 0)
            Text(homeMoney(total, currency: offer.currency))
                .font(AppFont.bold(size: 23))
                .foregroundStyle(AppColor.primary)
                .fixedSize(horizontal: false, vertical: true)
                .multilineTextAlignment(.trailing)
                .layoutPriority(1)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity)
        .background(AppColor.primary.opacity(0.06))
        .overlay(alignment: .top) {
            AppColor.primary.opacity(0.12)
                .frame(height: 1)
        }
    }
}
