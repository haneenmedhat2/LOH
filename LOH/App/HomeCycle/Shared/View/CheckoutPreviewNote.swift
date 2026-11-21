import SwiftUI

struct CheckoutPreviewNote: View {
    var body: some View {
        Text(homeText("noCharge"))
            .font(AppFont.regular(size: 12))
            .foregroundStyle(AppColor.secondaryText)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(12)
    }
}
