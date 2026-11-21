import SwiftUI

struct HomeCheckoutProgress: View {
    var size: CGFloat = 36

    var body: some View {
        BrandLoaderView(size: size)
            .accessibilityLabel(homeText("processingPayment"))
    }
}
