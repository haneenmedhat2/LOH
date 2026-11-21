import SwiftUI

struct PurchaseRatingRow: View {
    let rating: PurchaseDetail.Rating

    var body: some View {
        if let value = rating.displayValue {
            HStack(spacing: 8) {
                HStack(spacing: 0) {
                    ForEach(1...5, id: \.self) { star in
                        Image("lohPurchasesStarOutline")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 16, height: 16)
                            .overlay(alignment: .leading) {
                                Image("lohPurchasesStarFilled")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 16, height: 16)
                                    .mask(alignment: .leading) {
                                        Rectangle()
                                            .frame(width: 16 * min(1, max(0, value - Double(star - 1))))
                                    }
                            }
                    }
                }
                .environment(\.layoutDirection, .leftToRight)
                Text(rating.label ?? homeText("rated"))
                    .font(AppFont.regular(size: 13))
                    .foregroundStyle(AppColor.secondaryText)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(homeText("rating"))
            .accessibilityValue(homeNumber(value, decimals: 1))
        }
    }
}
