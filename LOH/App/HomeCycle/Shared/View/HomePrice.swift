import SwiftUI
import UIKit

struct HomePrice: View {
    let offer: HomeOffer
    var large = false
    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(homeMoney(offer.price, currency: offer.currency))
                .font(AppFont.extraBold(size: large ? 30 : 15))
                .foregroundStyle(AppColor.primary)
            if offer.originalPrice > offer.price {
                Text(homeMoney(offer.originalPrice, currency: offer.currency))
                    .font(AppFont.regular(size: 11))
                    .strikethrough()
                    .foregroundStyle(AppColor.mutedText)
            }
        }
    }
}
