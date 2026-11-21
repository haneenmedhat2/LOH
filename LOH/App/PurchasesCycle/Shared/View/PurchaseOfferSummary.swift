import SwiftUI

struct PurchaseOfferSummary: View {
    let name: String
    let merchant: String
    let image: String?
    var location: String = ""

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            HomePhoto(asset: image ?? "")
                .frame(width: 92, height: 92)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay {
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(AppColor.border.opacity(0.65), lineWidth: 1)
                }
            VStack(alignment: .leading, spacing: 8) {
                if !merchant.isEmpty {
                    Text(merchant)
                        .font(AppFont.medium(size: 12))
                        .foregroundStyle(AppColor.secondaryText)
                }
                Text(name)
                    .font(AppFont.bold(size: 17))
                    .foregroundStyle(AppColor.text)
                    .fixedSize(horizontal: false, vertical: true)
                if !location.isEmpty {
                    HStack(alignment: .top, spacing: 5) {
                        HomeIcon.pin.view(13)
                            .frame(height: 17)
                        Text(location)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .font(AppFont.regular(size: 12))
                    .foregroundStyle(AppColor.secondaryText)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
