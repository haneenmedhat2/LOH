import SwiftUI

/// Checkout chrome owns the top safe-area color independently of the scrolling canvas.
struct HomeCheckoutHeader: View {
    let step: Int
    var processing = false
    var body: some View {
        HomeCheckoutSteps(step: step, processing: processing, verticalPadding: 0)
            .padding(.top, 12)
            .padding(.bottom, step == 3 || processing ? 16 : 24)
            .background(
                AppColor.surface
                    .ignoresSafeArea(edges: .top))
    }
}
