import SwiftUI

struct HomeOfferMetadata: View {
    let offer: HomeOffer

    private var address: String? {
        offer.isRemote ? offer.branch?.address : homeText("district")
    }
    private var hasRating: Bool {
        offer.hasRating || offer.ratingText?.isEmpty == false
    }
    private var hasDistance: Bool {
        offer.hasDistance || offer.distanceText?.isEmpty == false
    }

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 10) {
                if hasRating {
                    rating
                }
                if let address, !address.isEmpty {
                    if hasRating {
                        separator
                    }
                    location(address)
                }
                if hasDistance {
                    if hasRating || address?.isEmpty == false {
                        separator
                    }
                    location(offer.distanceText ?? homeDistance(offer.distance))
                }
            }
            .fixedSize(horizontal: true, vertical: false)

            VStack(alignment: .leading, spacing: 8) {
                if hasRating {
                    rating
                }
                if let address, !address.isEmpty {
                    location(address)
                }
                if hasDistance {
                    location(offer.distanceText ?? homeDistance(offer.distance))
                }
            }
        }
        .font(AppFont.regular(size: 11))
        .foregroundStyle(AppColor.secondaryText)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var rating: some View {
        HStack(spacing: 4) {
            if offer.hasRating {
                HomeIcon.star.view(12)
                Text(homeNumber(offer.rating))
                    .font(AppFont.medium(size: 12))
                    .foregroundStyle(AppColor.text)
            }
            if let text = offer.ratingText, !text.isEmpty {
                Text(text)
                    .foregroundStyle(AppColor.mutedText)
            } else if let count = offer.ratingCount ?? (offer.isRemote ? nil : 128), count > 0 {
                Text(homeFormat("reviewsFormat", homeNumber(count)))
                    .foregroundStyle(AppColor.mutedText)
            }
        }
    }

    private func location(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 4) {
            HomeIcon.pin.view(14)
            Text(text)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var separator: some View {
        AppColor.border
            .frame(width: 1, height: 12)
    }
}
