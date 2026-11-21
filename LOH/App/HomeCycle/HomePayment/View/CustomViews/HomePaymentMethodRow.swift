import SwiftUI

struct HomePaymentMethodRow: View {
    let method: HomePaymentMethod
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                icon
                    .frame(width: 68)
                VStack(alignment: .leading, spacing: 4) {
                    Text(homeText(method.rawValue))
                        .font(AppFont.medium(size: 15))
                    Text(homeText(method == .cashback ? "checkoutCashbackHint" : method.rawValue + "Hint"))
                        .font(AppFont.regular(size: 12))
                        .foregroundStyle(method == .cashback ? AppColor.success : AppColor.secondaryText)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                HomeRadio(selected: isSelected)
            }
            .padding(14)
            .frame(minHeight: 76)
            .background(
                isSelected ? AppColor.primary.opacity(0.04) : AppColor.surface, in: RoundedRectangle(cornerRadius: 16)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(
                        isSelected ? AppColor.primary : AppColor.border.opacity(0.7), lineWidth: isSelected ? 1.5 : 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    @ViewBuilder private var icon: some View {
        switch method {
        case .applePay:
            HomeIcon.applePay.image
                .resizable()
                .scaledToFit()
                .frame(width: 40, height: 28)
        case .mada:
            HomeIcon.mada.image
                .resizable()
                .scaledToFit()
                .frame(width: 68, height: 22)
        case .card:
            HomeIcon.cards.image
                .resizable()
                .scaledToFit()
                .frame(width: 64, height: 23)
        case .cashback:
            HomeIcon.paymentCashback.view(40)
        }
    }
}
