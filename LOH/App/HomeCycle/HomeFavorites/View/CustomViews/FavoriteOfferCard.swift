import SwiftUI

func favoriteIcon(_ name: String, size: CGFloat) -> some View {
    Image("lohHome" + name)
        .resizable()
        .scaledToFit()
        .frame(width: size, height: size)
        .accessibilityHidden(true)
}

struct FavoriteOfferCard: View {
    @EnvironmentObject private var model: HomeViewModel
    let offer: HomeOffer
    let open: () -> Void
    private var photo: String {
        switch offer.id {
        case "grill": return "lohFavoriteBurger"
        case "massage": return "lohFavoriteSpa"
        default: return offer.asset
        }
    }
    private var merchantMark: String {
        switch offer.id {
        case "nawa": return "NAWA"
        case "grill": return "GRILL"
        case "massage": return "SPA"
        case "cinema": return "CIN"
        default: return String(offer.merchant.prefix(3)).uppercased()
        }
    }
    var body: some View {
        Button(action: open) {
            VStack(alignment: .leading, spacing: 0) {
                HomePhoto(asset: photo)
                    .aspectRatio(1.2, contentMode: .fit)
                    .background(AppColor.canvas)
                    .overlay(Rectangle().strokeBorder(AppColor.canvas, lineWidth: 1))
                    .overlay(alignment: .bottomTrailing) {
                        if offer.discount > 0 {
                            Text(homeFormat("saveFormat", homePercent(offer.discount)))
                                .font(AppFont.bold(size: 11))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8)
                                .frame(height: 32)
                                .background(AppColor.primary, in: RoundedRectangle(cornerRadius: 8))
                                .padding(8)
                        }
                    }
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        if let image = offer.merchantImage, !image.isEmpty {
                            HomePhoto(asset: image)
                                .frame(width: 32, height: 32)
                                .clipShape(Circle())
                                .overlay(Circle().strokeBorder(AppColor.canvas, lineWidth: 1))
                                .accessibilityHidden(true)
                        } else {
                            Text(merchantMark)
                                .font(.system(size: 7, weight: .black))
                                .foregroundStyle(.white)
                                .frame(width: 32, height: 32)
                                .background(AppColor.text, in: Circle())
                                .accessibilityHidden(true)
                        }
                        Text(offer.displayMerchant)
                            .font(AppFont.bold(size: 13))
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .environment(\.layoutDirection, .leftToRight)
                    Text(offer.displayTitle)
                        .font(AppFont.regular(size: 12))
                        .foregroundStyle(AppColor.secondaryText)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    if offer.hasDistance {
                        HStack(spacing: 4) {
                            HomeIcon.pin.view(10)
                            Text(offer.distanceText ?? homeDistance(offer.distance))
                                .font(AppFont.regular(size: 10))
                        }
                        .foregroundStyle(AppColor.mutedText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    ViewThatFits(in: .horizontal) {
                        HStack(alignment: .firstTextBaseline, spacing: 6) {
                            currentPrice
                            Spacer(minLength: 0)
                            originalPrice
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            currentPrice
                            originalPrice
                        }
                    }

                }
                .padding(12)
            }
            .frame(maxWidth: .infinity)
            .background(AppColor.surface)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Color(white: 0.94), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .overlay(alignment: .topTrailing) {
            Button {
                model.toggleFavorite(offer.id, language: AppLanguageManager.shared.apiLanguage)
            } label: {
                Group {
                    if model.updatingFavorites.contains(offer.id) {
                        BrandLoaderView(size: 24)
                    } else {
                        HomeIcon.heartFilled.view(16, color: AppColor.primary)
                    }
                }
                .frame(width: 32, height: 32)
                .background(AppColor.surface, in: Circle())
                .shadow(color: .black.opacity(0.1), radius: 2, y: 1)
                .frame(width: 48, height: 48)
            }
            .buttonStyle(.plain)
            .disabled(model.updatingFavorites.contains(offer.id))
            .accessibilityLabel(homeText("unfavorite"))
        }
    }
    private var currentPrice: some View {
        Text(homeMoney(offer.price, currency: offer.currency))
            .font(AppFont.black(size: 17))
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

}
