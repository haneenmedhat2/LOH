import SwiftUI

struct PaymentCardDialog: View {
    let route: PaymentCardDialogRoute
    let cancel: () -> Void
    let confirm: (String) -> Void
    @State private var name = ""

    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
            VStack(spacing: 0) {
                switch route {
                case .delete(let card):
                    LOHAsset.paymentDeleteIllustration.image
                        .resizable()
                        .frame(width: 96, height: 97)
                        .overlay(alignment: .bottomLeading) {
                            LOHAsset.paymentDeleteDecoration.image
                                .resizable()
                                .frame(width: 28, height: 24)
                                .offset(x: -12, y: 8)
                        }
                        .accessibilityHidden(true)
                        .padding(.bottom, 16)
                    Text("more.Remove card?".localized)
                        .font(AppFont.extraBold(size: 20))
                        .padding(.bottom, 8)
                    Text(String(format: "payments.deleteMessage".localized, card.paymentTitle, card.lastFour))
                        .font(AppFont.regular(size: 14))
                        .foregroundStyle(AppColor.secondaryText)
                        .padding(.bottom, 4)
                    Text("payments.purchaseUnaffected".localized)
                        .font(AppFont.regular(size: 13))
                        .foregroundStyle(AppColor.mutedText)
                        .padding(.bottom, 24)
                    MainAppButton(
                        title: "payments.confirmDelete".localized,
                        action: { confirm("") }, variant: .action, height: 56)
                case .rename:
                    Text("payments.rename".localized)
                        .font(AppFont.bold(size: 17))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.bottom, 16)
                    TextField("payments.cardName".localized, text: $name)
                        .font(AppFont.regular(size: 15))
                        .foregroundStyle(AppColor.text)
                        .tint(AppColor.primary)
                        .padding(.horizontal, 16)
                        .frame(height: 55)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .strokeBorder(AppColor.primary, lineWidth: 2))
                        .padding(.bottom, 20)
                    MainAppButton(
                        title: "more.Save".localized,
                        action: { confirm(name) }, variant: .action,
                        isEnabled: !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && name.count <= 100,
                        height: 56)
                }
                Button(action: cancel) {
                    Text("more.Cancel".localized)
                }
                .buttonStyle(MainButtonStyle(variant: .secondary, foregroundColor: AppColor.primary, height: 56))
                .padding(.top, 12)
            }
            .multilineTextAlignment(.center)
            .foregroundStyle(AppColor.text)
            .padding(24)
            .frame(maxWidth: 342)
            .background(AppColor.surface, in: RoundedRectangle(cornerRadius: 24))
            .padding(24)
            .accessibilityAddTraits(.isModal)
        }
        .onAppear {
            if case .rename(let card) = route { name = card.paymentTitle }
        }
        .logScreen(
            {
                if case .delete = route { return "payment-card-delete" }
                return "payment-card-rename"
            }())
    }
}
