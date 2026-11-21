import SwiftUI

struct PurchaseDetailRatingCard: View {
    let rating: PurchaseDetail.Rating
    let onRate: (Int) -> Void

    var body: some View {
        CardContainer(padding: 16, cornerRadius: 16) {
            VStack(spacing: 16) {
                Text(homeText(rating.isRated ? "rated" : "howWasExperience"))
                    .font(AppFont.bold(size: 15))
                    .frame(maxWidth: .infinity, alignment: .leading)
                PurchaseRatingStars(
                    value: rating.displayValue ?? 0,
                    onSelect: rating.isRated ? nil : onRate
                )
                if rating.isRated {
                    if let label = rating.label, !label.isEmpty {
                        Text(label)
                            .font(AppFont.medium(size: 13))
                            .foregroundStyle(AppColor.success)
                    }
                    if let comment = rating.comment, !comment.isEmpty {
                        Text(comment)
                            .font(AppFont.regular(size: 13))
                            .foregroundStyle(AppColor.secondaryText)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                } else {
                    Text(homeText("ratingHint"))
                        .font(AppFont.regular(size: 12))
                        .foregroundStyle(AppColor.secondaryText)
                        .multilineTextAlignment(.center)
                    Button {
                        onRate(0)
                    } label: {
                        Text(homeText("purchaseRateAction"))
                    }
                    .buttonStyle(
                        MainButtonStyle(variant: .outlined, height: 52, cornerRadius: 12, font: AppFont.bold(size: 15))
                    )
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
}
