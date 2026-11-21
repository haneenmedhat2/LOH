import SwiftUI

struct HomeMerchantOffers: View {
    let merchant: HomeMerchant
    let offers: [HomeOffer]
    let selectedCategoryID: Int?
    let isLoading: Bool
    let error: String?
    let canSelectCategory: Bool
    let onCategory: (Int) -> Void
    let onRetry: () -> Void
    let onOffer: (HomeOffer) -> Void
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(homeFormat("merchantOffersFormat", merchant.name))
                .font(AppFont.bold(size: 16))
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(merchant.categories) { category in
                        HomeChip(title: category.name, selected: category.id == (selectedCategoryID ?? 17)) {
                            onCategory(category.id)
                        }
                    }
                }
                .disabled(!canSelectCategory)
            }
            if isLoading {
                BrandLoaderView(size: 56)
                    .frame(maxWidth: .infinity, minHeight: 160)
            } else if let error {
                HomeAPIError(message: error, retry: onRetry)
            } else if offers.isEmpty {
                Text(homeText("noCategoryOffers"))
                    .font(AppFont.regular(size: 14))
                    .foregroundStyle(AppColor.secondaryText)
                    .frame(maxWidth: .infinity, minHeight: 100)
            } else {
                LazyVGrid(
                    columns: Array(
                        repeating: GridItem(.flexible(), spacing: 8), count: dynamicTypeSize.isAccessibilitySize ? 2 : 3
                    ), alignment: .leading, spacing: 16
                ) {
                    ForEach(offers) { offer in
                        HomeMerchantOfferCard(offer: offer) { onOffer(offer) }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct HomeMerchantOfferCard: View {
    let offer: HomeOffer
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 6) {
                HomePhoto(asset: offer.asset)
                    .frame(height: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay {
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(AppColor.border, lineWidth: 1)
                            .allowsHitTesting(false)
                    }
                    .overlay(alignment: .topLeading) {
                        if offer.available {
                            Text(homeText("available"))
                                .font(AppFont.medium(size: 10))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 5)
                                .background(AppColor.success, in: RoundedRectangle(cornerRadius: 8))
                                .padding(5)
                        }
                    }
                Text(offer.displayTitle)
                    .font(AppFont.medium(size: 12))
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 4) {
                        price
                        originalPrice
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        price
                        originalPrice
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var price: some View {
        Text(homeMoney(offer.price, currency: offer.currency))
            .font(AppFont.extraBold(size: 14))
            .foregroundStyle(AppColor.primary)
    }

    @ViewBuilder private var originalPrice: some View {
        if offer.originalPrice > offer.price {
            Text(homeMoney(offer.originalPrice, currency: offer.currency))
                .font(AppFont.regular(size: 11))
                .foregroundStyle(AppColor.mutedText)
                .strikethrough()
        }
    }
}
