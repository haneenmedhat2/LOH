import SwiftUI

struct HomeMerchantLocationCard: View {
    let merchant: HomeMerchant

    private var address: String? { merchant.location?.address ?? merchant.address ?? merchant.locationText }
    private var distance: HomeMerchantDistance? { merchant.location?.distance ?? merchant.distance }

    var body: some View {
        if merchant.location?.hasCoordinates == true,
            (address?.isEmpty == false || distance != nil || merchant.location?.url != nil) {
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text(homeText("location"))
                            .font(AppFont.bold(size: 16))
                        Spacer()
                        if let url = merchant.location?.url {
                            HomeMerchantDirections(url: url, title: merchant.location?.directionsLabel, compact: true)
                        }
                    }
                    if let address, !address.isEmpty {
                        Text(address)
                            .font(AppFont.regular(size: 13))
                            .foregroundStyle(AppColor.secondaryText)
                    }
                    if let distance {
                        Text(distance.displayText)
                            .font(AppFont.regular(size: 13))
                            .foregroundStyle(AppColor.secondaryText)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                Image("lohMerchantMap")
                    .resizable()
                    .aspectRatio(348.0 / 120, contentMode: .fit)
                    .accessibilityHidden(true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppColor.surface)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(AppColor.border.opacity(0.5))
            }
        }
    }
}

struct HomeMerchantDirections: View {
    let url: URL
    var title: String?
    var compact = false

    var body: some View {
        Link(destination: url) {
            HStack(spacing: 8) {
                HomeIcon.directions.view(compact ? 14 : 18, color: compact ? AppColor.primary : AppColor.text)
                Text(title ?? homeText("directions"))
                    .font(AppFont.medium(size: compact ? 13 : 14))
            }
            .foregroundStyle(compact ? AppColor.primary : AppColor.text)
            .padding(.horizontal, compact ? 12 : 0)
            .frame(maxWidth: compact ? nil : .infinity, minHeight: compact ? 38 : 47)
            .background(AppColor.surface, in: RoundedRectangle(cornerRadius: compact ? 12 : 16))
            .overlay {
                RoundedRectangle(cornerRadius: compact ? 12 : 16)
                    .strokeBorder(compact ? AppColor.primary : AppColor.border)
            }
        }
        .buttonStyle(.plain)
    }
}
