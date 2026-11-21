import SwiftUI
import UIKit

struct HomeOfferCard: View {
    @EnvironmentObject private var model: HomeViewModel
    let offer: HomeOffer
    let open: () -> Void
    var body: some View {
        Button(action: open) {
            content
        }
        .buttonStyle(.plain)
        .overlay(alignment: .topTrailing) {
            Button {
                model.toggleFavorite(offer.id, language: AppLanguageManager.shared.apiLanguage)
            } label: {
                (model.favorites.contains(offer.id) ? HomeIcon.heartFilled : .heart).view(14)
                    .frame(width: 28, height: 28)
                    .background(AppColor.surface, in: Circle())
                    .overlay(
                        Circle()
                            .strokeBorder(
                                model.favorites.contains(offer.id) ? AppColor.primary.opacity(0.5) : AppColor.border,
                                lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.08), radius: 1, y: 1)
                    .frame(width: AppMetrics.touchTarget, height: AppMetrics.touchTarget)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(homeText(model.favorites.contains(offer.id) ? "unfavorite" : "favorite"))
        }
    }
    private var content: some View {
        VStack(alignment: .leading, spacing: 0) {
            HomePhoto(asset: offer.asset)
                .frame(height: 118)
                .background(AppColor.canvas)
                .overlay(
                    Rectangle()
                        .strokeBorder(AppColor.canvas, lineWidth: 1)
                )
                .overlay(alignment: .topLeading) {
                    if offer.hasDistance {
                        HStack(spacing: 2) {
                            HomeIcon.pin.view(10)
                            Text(homeDistance(offer.distance))
                                .font(AppFont.regular(size: 10))
                        }
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(AppColor.surface, in: Capsule())
                        .padding(8)
                    }
                }
                .overlay(alignment: .bottomTrailing) {
                    if offer.available {
                        HomeAvailability()
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(AppColor.surface, in: Capsule())
                            .padding(8)
                    }
                }
            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 4) {
                    if !offer.isRemote {
                        (offer.category == .restaurants ? HomeIcon.restaurant : .cafe).view(12)
                    }
                    Text(offer.displayMerchant)
                        .font(AppFont.regular(size: 11))
                        .foregroundStyle(AppColor.secondaryText)
                }
                Text(offer.displayTitle)
                    .font(AppFont.bold(size: 13))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .lineLimit(2)
                HomePrice(offer: offer)
                if offer.discount > 0 {
                    Text(homeFormat("discountFormat", homePercent(offer.discount)))
                        .font(AppFont.medium(size: 10))
                        .foregroundStyle(AppColor.primary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(AppColor.errorSurface, in: Capsule())
                }
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(width: 168)
        .fixedSize(horizontal: false, vertical: true)
        .background(AppColor.surface, in: RoundedRectangle(cornerRadius: 16))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(AppColor.border.opacity(0.6), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.06), radius: 2, y: 2)

    }
}
