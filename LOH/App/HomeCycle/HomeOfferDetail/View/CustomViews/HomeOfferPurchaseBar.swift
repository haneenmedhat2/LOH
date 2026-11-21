import SwiftUI

struct HomeOfferPurchaseBar: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let offer: HomeOffer
    let isEnabled: Bool
    let purchase: () -> Void

    var body: some View {
        let layout =
            dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 12))
            : AnyLayout(HStackLayout(spacing: 20))

        layout {
            VStack(alignment: .leading, spacing: 4) {
                Text(homeText("total"))
                    .font(AppFont.regular(size: 11))
                    .foregroundStyle(AppColor.secondaryText)
                Text(homeMoney(offer.payablePrice, currency: offer.currency))
                    .font(AppFont.black(size: 20))
                    .foregroundStyle(AppColor.primary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Button(action: purchase) {
                VStack(spacing: 4) {
                    HStack(spacing: 8) {
                        HomeIcon.lock.view(16, color: isEnabled ? .white : AppColor.secondaryText)
                        Text(homeText("buyOffer"))
                            .font(AppFont.bold(size: 16))
                    }
                    Text(homeText("securePayment"))
                        .font(AppFont.regular(size: 11))
                }
                .foregroundStyle(isEnabled ? Color.white : AppColor.secondaryText)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .frame(minWidth: dynamicTypeSize.isAccessibilitySize ? nil : 179, minHeight: 65)
                .frame(maxWidth: dynamicTypeSize.isAccessibilitySize ? .infinity : nil)
                .background(isEnabled ? AppColor.primary : AppColor.disabledSurface, in: RoundedRectangle(cornerRadius: 16))
            }
            .buttonStyle(.plain)
            .disabled(!isEnabled)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(AppColor.surface)
        .overlay(alignment: .top) {
            AppColor.border.opacity(0.5)
                .frame(height: 1)
        }
    }
}
