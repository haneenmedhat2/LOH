import SwiftUI

struct HomeOfferRow: View {
    let offer: HomeOffer
    let open: () -> Void
    private let imageWidth: CGFloat = 128

    var body: some View {
        Button(action: open) {
            HStack(alignment: .top, spacing: 0) {
                Color.clear
                    .frame(width: imageWidth)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 6) {
                    if !offer.displayMerchant.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text(offer.displayMerchant)
                            .font(AppFont.extraBold(size: 16))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Text(offer.displayTitle)
                        .font(AppFont.regular(size: 13))
                        .foregroundStyle(AppColor.secondaryText)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                    ViewThatFits(in: .horizontal) {
                        prices
                        VStack(alignment: .leading, spacing: 4) {
                            currentPrice
                            originalPrice
                        }
                    }
                    .padding(.top, 2)
                    if offer.discount > 0 {
                        Text(homeFormat("discountFormat", homePercent(offer.discount)))
                            .font(AppFont.bold(size: 10))
                            .foregroundStyle(AppColor.primary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(AppColor.accentSurface, in: Capsule())
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                    if offer.hasDistance || offer.available || offer.hasRating {
                        ViewThatFits(in: .horizontal) {
                            metadata
                            VStack(alignment: .leading, spacing: 6) {
                                distance
                                availability
                                rating
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .fixedSize(horizontal: false, vertical: true)
            .frame(minHeight: 118)
            .background(alignment: .leading) {
                HomePhoto(asset: offer.asset)
                    .frame(width: imageWidth)
                    .background(AppColor.canvas)
                    .overlay {
                        Rectangle().strokeBorder(AppColor.canvas, lineWidth: 1)
                    }
            }
            .foregroundStyle(AppColor.text)
            .background(AppColor.surface)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(AppColor.border.opacity(0.65)))
            .shadow(color: .black.opacity(0.035), radius: 5, y: 2)
        }
        .buttonStyle(.plain)
    }

    private var prices: some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            currentPrice
            originalPrice
        }
    }

    private var currentPrice: some View {
        Text(homeMoney(offer.price, currency: offer.currency))
            .font(AppFont.extraBold(size: 16))
            .foregroundStyle(AppColor.primary)
    }

    @ViewBuilder private var originalPrice: some View {
        if offer.originalPrice > offer.price {
            Text(homeMoney(offer.originalPrice, currency: offer.currency))
                .font(AppFont.regular(size: 12))
                .strikethrough()
                .foregroundStyle(AppColor.mutedText)
        }
    }

    private var metadata: some View {
        HStack(spacing: 10) {
            distance.fixedSize()
            availability.fixedSize()
            rating.fixedSize()
        }
    }

    @ViewBuilder private var distance: some View {
        if offer.hasDistance {
            HStack(spacing: 4) {
                HomeIcon.pin.view(10)
                Text(offer.distanceText ?? homeDistance(offer.distance))
                    .font(AppFont.regular(size: 11))
            }
            .foregroundStyle(AppColor.secondaryText)
        }
    }

    @ViewBuilder private var availability: some View {
        if offer.available { HomeAvailability() }
    }

    @ViewBuilder private var rating: some View {
        if offer.hasRating {
            HStack(spacing: 3) {
                HomeIcon.star.view(10)
                Text(homeNumber(offer.rating))
                    .font(AppFont.regular(size: 10))
            }
        }
    }
}
