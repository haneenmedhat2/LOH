import SwiftUI

struct PaymentCardActionsSheet: View {
    let card: AccountCard
    let makeDefault: () -> Void
    let rename: () -> Void
    let delete: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                PaymentBrandLogo(brand: card.brand)
                VStack(alignment: .leading, spacing: 2) {
                    Text(card.paymentTitle + " •••• " + card.lastFour)
                        .font(AppFont.bold(size: 15))
                    Text(String(format: "payments.expiresFormat".localized, card.expiry))
                        .font(AppFont.regular(size: 13))
                        .foregroundStyle(AppColor.secondaryText)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.bottom, 16)
            .overlay(alignment: .bottom) { profileDivider }
            VStack(spacing: 8) {
                if !card.isDefault {
                    actionRow("more.Set as default card", icon: .paymentDefault, action: makeDefault)
                }
                actionRow("payments.rename", icon: .paymentRename, action: rename)
                actionRow("more.Remove card", icon: .paymentDelete, destructive: true, action: delete)
            }
            .padding(.top, 16)
            Text("payments.purchaseUnaffected".localized)
                .font(AppFont.regular(size: 12))
                .foregroundStyle(AppColor.mutedText)
                .multilineTextAlignment(.center)
                .padding(.top, 16)
        }
        .padding(.horizontal, 16)
        .padding(.top, 24)
        .padding(.bottom, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .foregroundStyle(AppColor.text)
        .background(AppColor.surface)
        .logScreen("payment-card-actions")
    }

    private func actionRow(_ title: String, icon: LOHAsset, destructive: Bool = false, action: @escaping () -> Void)
        -> some View {
        Button(action: action) {
            HStack {
                profileIcon(icon, size: 20)
                Spacer()
                Text(title.localized)
                    .font(AppFont.mediumButton)
            }
            .padding(.horizontal, 16)
            .frame(minHeight: 55)
            .foregroundStyle(destructive ? AppColor.primary : AppColor.text)
            .background(
                destructive ? AppColor.accentSurface : AppColor.accountCanvas,
                in: RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }
}
