import SwiftUI

struct HomeCheckoutBar: View {
    let total: Double
    let title: String
    var currency: String? = nil
    let action: () -> Void
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(homeText("total"))
                    .font(AppFont.regular(size: 11))
                    .foregroundStyle(AppColor.secondaryText)
                Text(homeMoney(total, currency: currency))
                    .font(AppFont.black(size: 18))
                    .foregroundStyle(AppColor.primary)
            }
            Button(action: action) {
                HStack(spacing: 8) {
                    Image("lohCheckoutButtonLock")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16, height: 16)
                        .accessibilityHidden(true)
                    Text(homeText(title))
                }
            }
            .buttonStyle(MainButtonStyle(variant: .action, height: 56, font: AppFont.bold(size: 16)))
        }
        .padding(16)
        .background(AppColor.surface)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(AppColor.border.opacity(0.5))
                .frame(height: 1)
        }
    }
}
