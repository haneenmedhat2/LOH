import SwiftUI

struct PurchaseRatingSuccessPopup: View {
    let dismiss: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
            GeometryReader { geometry in
                ScrollView {
                    successCard
                        .frame(maxWidth: .infinity, minHeight: geometry.size.height)
                }
                .scrollBounceBehavior(.basedOnSize)
                .accessibilityAddTraits(.isModal)
            }
        }
        .logScreen("PurchaseRatingSuccessPopup")
    }

    private var successCard: some View {
        VStack(spacing: 0) {
            Image("lohPurchasesRatingSuccess")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .overlay {
                    Circle()
                        .fill(AppColor.primary)
                        .frame(width: 6, height: 6)
                        .offset(x: 21, y: -15)
                    Circle()
                        .fill(AppColor.primary)
                        .frame(width: 6, height: 6)
                        .offset(x: -15, y: 17)
                }
                .accessibilityHidden(true)
                .padding(.bottom, 16)
            Text(homeText("ratingSubmitted"))
                .font(AppFont.extraBold(size: 20))
                .padding(.bottom, 8)
            Text(homeText("thanksRating"))
                .font(AppFont.medium(size: 15))
                .padding(.bottom, 4)
            Text(homeText("ratingSuccessHint"))
                .font(AppFont.regular(size: 13))
                .foregroundStyle(AppColor.secondaryText)
                .lineSpacing(3)
                .padding(.bottom, 24)
            Button(action: dismiss) {
                Text(homeText("done"))
            }
            .buttonStyle(
                MainButtonStyle(variant: .action, height: 56, cornerRadius: 16, font: AppFont.bold(size: 16))
            )
        }
        .multilineTextAlignment(.center)
        .foregroundStyle(AppColor.text)
        .padding(24)
        .frame(maxWidth: 342)
        .background {
            RoundedRectangle(cornerRadius: 24)
                .fill(AppColor.surface)
                .shadow(color: .black.opacity(0.25), radius: 25, y: 25)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity)
    }
}
