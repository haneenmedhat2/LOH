import SwiftUI

struct HomeCheckoutSavedCardRow: View {
    let card: AccountCard
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                PaymentBrandLogo(brand: card.brand == "master" ? "mastercard" : card.brand)
                    .frame(width: 50)
                VStack(alignment: .leading, spacing: 4) {
                    ViewThatFits(in: .horizontal) {
                        HStack(spacing: 8) {
                            defaultBadge
                            number
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            defaultBadge
                            number
                        }
                    }
                    if !card.expiry.isEmpty {
                        Text(String(format: "payments.expiresFormat".localized, card.expiry))
                            .font(AppFont.regular(size: 12))
                            .foregroundStyle(AppColor.secondaryText)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                HomeRadio(selected: isSelected)
            }
            .padding(.vertical, 12)
            .frame(minHeight: 64)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(HomeOrderPaymentType.cardBrand(card.brand) == nil)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var number: some View {
        Text("•••• " + card.lastFour)
            .font(AppFont.bold(size: 14))
            .environment(\.layoutDirection, .leftToRight)
    }

    @ViewBuilder private var defaultBadge: some View {
        if card.isDefault {
            Text("more.Default card".localized)
                .font(AppFont.regular(size: 10))
                .foregroundStyle(AppColor.primary)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(AppColor.accentSurface, in: Capsule())
                .overlay {
                    Capsule()
                        .strokeBorder(AppColor.primary, lineWidth: 1)
                }
        }
    }
}
