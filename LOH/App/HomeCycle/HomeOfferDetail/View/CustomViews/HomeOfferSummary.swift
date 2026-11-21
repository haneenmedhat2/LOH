import SwiftUI

struct HomeOfferSummary: View {
    let offer: HomeOffer
    let showsStore: Bool
    let onStore: () -> Void
    var showsPricing = true

    private var showsMetadata: Bool {
        !offer.isRemote || offer.hasRating || offer.ratingText?.isEmpty == false
            || offer.hasDistance || offer.distanceText?.isEmpty == false || offer.branch?.address?.isEmpty == false
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                HomeMerchantLogo(offer: offer)

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(offer.displayMerchant)
                            .font(AppFont.bold(size: 16))
                        if !offer.isRemote || offer.store?.isVerified == true {
                            HomeIcon.verified.view(16)
                        }
                    }

                    if showsStore {
                        Button(action: onStore) {
                            HStack(spacing: 4) {
                                Text(homeText("viewMerchant"))
                                    .font(AppFont.medium(size: 13))
                                Image(systemName: "chevron.forward")
                                    .font(.system(size: 9, weight: .semibold))
                            }
                            .foregroundStyle(AppColor.primary)
                            .frame(minHeight: 28)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            Text(offer.displayTitle)
                .font(AppFont.extraBold(size: 22))
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)

            if showsMetadata {
                HomeOfferMetadata(offer: offer)
            }

            if showsPricing {
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .center, spacing: 20) {
                        price
                        Spacer(minLength: 12)
                        availability
                    }
                    VStack(alignment: .leading, spacing: 12) {
                        price
                        availability
                    }
                }
                .padding(.top, 4)
            }
        }
    }

    private var price: some View {
        VStack(alignment: .leading, spacing: 4) {
            if offer.originalPrice > offer.price {
                HStack(spacing: 8) {
                    if offer.discount > 0 {
                        Text(homeFormat("saveFormat", homePercent(offer.discount)))
                            .font(AppFont.bold(size: 12))
                            .foregroundStyle(AppColor.primary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(AppColor.errorSurface, in: Capsule())
                    }
                    Text(homeMoney(offer.originalPrice, currency: offer.currency))
                        .font(AppFont.regular(size: 12))
                        .strikethrough()
                        .foregroundStyle(AppColor.mutedText)
                }
            }
            Text(homeMoney(offer.price, currency: offer.currency))
                .font(AppFont.black(size: 34))
                .foregroundStyle(AppColor.primary)
                .fixedSize(horizontal: true, vertical: false)
            if let fee = offer.serviceFee {
                Text("\(homeText("serviceFee")): \(homeMoney(fee, currency: offer.currency))")
                    .font(AppFont.regular(size: 11))
                    .foregroundStyle(AppColor.secondaryText)
            }
        }
    }

    private var availability: some View {
        VStack(alignment: .trailing, spacing: 6) {
            HomeOfferStatus(
                text: offer.availabilityStatus ?? homeText(offer.available ? "available" : "unavailable"),
                isOpen: offer.available
            )
            if let time = offer.availableTimeText, !time.isEmpty {
                Text(time)
                    .font(AppFont.regular(size: 11))
                    .foregroundStyle(AppColor.secondaryText)
            } else if !offer.isRemote {
                Text(homeText("openingHours"))
                    .font(AppFont.regular(size: 11))
                    .foregroundStyle(AppColor.secondaryText)
            }
        }
    }
}
