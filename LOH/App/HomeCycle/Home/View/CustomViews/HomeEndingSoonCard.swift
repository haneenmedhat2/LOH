import SwiftUI
import UIKit

struct HomeEndingSoonCard: View {
    @EnvironmentObject private var model: HomeViewModel
    let offer: HomeOffer
    let expiresAt: Date?
    let open: () -> Void
    private let imageWidth: CGFloat = 128
    var body: some View {
        Button(action: open) {
            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: AppSpacing.small) {
                    HStack(spacing: 8) {
                        Text(offer.displayMerchant)
                            .font(AppFont.bold(size: 15))
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                        if offer.discount > 0 {
                            Text(homeFormat("discountFormat", homePercent(offer.discount)))
                                .font(AppFont.bold(size: 10))
                                .foregroundStyle(AppColor.primary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(AppColor.error.opacity(0.1), in: Capsule())
                        }
                    }
                    Text(offer.categoryName ?? offer.displayTitle)
                        .font(AppFont.regular(size: 12))
                        .foregroundStyle(AppColor.secondaryText)
                    if let expiresAt {
                        TimelineView(.periodic(from: .now, by: 1)) { timeline in
                            let seconds = max(0, Int(expiresAt.timeIntervalSince(timeline.date)))
                            HStack(spacing: 4) {
                                HomeIcon.clock.view(12, color: AppColor.primary)
                                Text(
                                    homeFormat(
                                        "endsIn",
                                        String(
                                            format: "%02d:%02d:%02d", seconds / 3600, seconds / 60 % 60, seconds % 60))
                                )
                                .font(AppFont.medium(size: 11))
                                .foregroundStyle(AppColor.primary)
                            }
                        }
                    } else if let endsIn = offer.endsIn, !endsIn.isEmpty {
                        HStack(spacing: 4) {
                            HomeIcon.clock.view(12, color: AppColor.primary)
                            Text(homeFormat("endsIn", endsIn))
                                .font(AppFont.medium(size: 11))
                                .foregroundStyle(AppColor.primary)
                        }
                    }
                    HStack(spacing: 6) {
                        Text(homeMoney(offer.price, currency: offer.currency))
                            .font(AppFont.extraBold(size: 16))
                            .foregroundStyle(AppColor.primary)
                        if offer.originalPrice > offer.price {
                            Text(homeMoney(offer.originalPrice, currency: offer.currency))
                                .font(AppFont.regular(size: 12))
                                .strikethrough()
                                .foregroundStyle(AppColor.mutedText)
                        }
                    }
                    .padding(.top, 4)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                Color.clear
                    .frame(width: imageWidth)
                    .accessibilityHidden(true)
            }
            .fixedSize(horizontal: false, vertical: true)
            .frame(minHeight: 118)
            .background(alignment: .trailing) {
                HomePhoto(asset: offer.asset)
                    .frame(width: imageWidth)
                    .background(AppColor.canvas)
                    .overlay(
                        Rectangle()
                            .strokeBorder(AppColor.canvas, lineWidth: 1))
            }
            .background(AppColor.surface, in: RoundedRectangle(cornerRadius: 16))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color(white: 0.94))
            )
            .shadow(color: .black.opacity(0.08), radius: 2, y: 1)
        }
        .buttonStyle(.plain)
        .overlay(alignment: .topTrailing) {
            Button {
                model.toggleFavorite(offer.id, language: AppLanguageManager.shared.apiLanguage)
            } label: {
                (model.favorites.contains(offer.id) ? HomeIcon.heartFilled : .heart).view(12)
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
}
