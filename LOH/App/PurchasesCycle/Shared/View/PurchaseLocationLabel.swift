import SwiftUI

struct PurchaseLocationLabel: View {
    let address: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 4) {
            Image("lohPurchaseLocation")
                .resizable()
                .scaledToFit()
                .frame(width: 12, height: 12)
                .accessibilityHidden(true)
            Text(address)
                .font(AppFont.regular(size: 12))
                .foregroundStyle(AppColor.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
