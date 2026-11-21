import SwiftUI

struct HomeMerchantLogo: View {
    let offer: HomeOffer
    var body: some View {
        VStack(spacing: 3) {
            if let image = offer.merchantImage {
                HomePhoto(asset: image)
                    .frame(width: 56, height: 56)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            } else if offer.merchant == "Nawa Café" {
                HomeIcon.merchantLogo.view(22)
                Text("NAWA")
                    .font(AppFont.bold(size: 7))
                    .foregroundStyle(AppColor.success)
            } else {
                Text(String(offer.merchant.prefix(2)).uppercased())
                    .font(AppFont.bold(size: 20))
                    .foregroundStyle(AppColor.primary)
            }
        }
        .frame(width: 56, height: 56)
        .background(
            offer.isRemote ? AppColor.canvas : Color(red: 248 / 255, green: 249 / 255, blue: 240 / 255),
            in: RoundedRectangle(cornerRadius: 16)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(AppColor.border.opacity(0.5), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.06), radius: 2, y: 1)
    }
}
