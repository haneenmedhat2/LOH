import SwiftUI

struct HomeCheckoutSecurityCard: View {
    var body: some View {
        CardContainer(padding: 18, cornerRadius: 20, border: AppColor.border.opacity(0.5)) {
            HStack(spacing: 12) {
                HomeIcon.paymentShield.view(22)
                    .frame(width: 48, height: 48)
                    .background(AppColor.primary.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
                VStack(alignment: .leading, spacing: 6) {
                    Text(homeText("secureCheckout"))
                        .font(AppFont.bold(size: 15))
                    Text(homeText("secureCheckoutHint"))
                        .font(AppFont.regular(size: 12))
                        .foregroundStyle(AppColor.secondaryText)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}
