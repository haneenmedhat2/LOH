import SwiftUI

struct HomeMerchantHeader: View {
    let cover: String?

    var body: some View {
        HomePhoto(asset: cover ?? "")
            .overlay(alignment: .top) {
                LinearGradient(colors: [.black.opacity(0.25), .clear], startPoint: .top, endPoint: .bottom)
                    .frame(height: 110)
                    .allowsHitTesting(false)
            }
            .overlay {
                Rectangle()
                    .strokeBorder(AppColor.border, lineWidth: 1)
                    .allowsHitTesting(false)
            }
    }
}
