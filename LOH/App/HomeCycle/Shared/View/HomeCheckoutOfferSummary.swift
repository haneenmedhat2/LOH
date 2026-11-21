import SwiftUI

struct HomeCheckoutOfferSummary: View {
    let offer: HomeOffer
    var total: Double? = nil
    var showsAvailability = false
    var onMerchant: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .center, spacing: 16) {
                HomePhoto(asset: offer.asset)
                    .frame(width: showsAvailability ? 104 : 88, height: showsAvailability ? 104 : 88)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay {
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(AppColor.border.opacity(0.6), lineWidth: 1)
                    }
                VStack(alignment: .leading, spacing: 8) {
                    merchant
                    Text(offer.displayTitle)
                        .font(AppFont.bold(size: showsAvailability ? 18 : 16))
                        .foregroundStyle(AppColor.text)
                        .fixedSize(horizontal: false, vertical: true)
                    if showsAvailability {
                        availability
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            if showsAvailability && (offer.checkoutAddress != nil || offer.checkoutHours != nil) {
                VStack(alignment: .leading, spacing: 10) {
                    if let address = offer.checkoutAddress {
                        metadata(address, icon: .pin)
                    }
                    if let hours = offer.checkoutHours {
                        metadata(hours, icon: .clock)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            if let total {
                Divider()
                    .overlay(AppColor.border.opacity(0.5))
                HStack(alignment: .firstTextBaseline) {
                    Text(homeText("total"))
                        .font(AppFont.medium(size: 13))
                        .foregroundStyle(AppColor.secondaryText)
                    Spacer(minLength: 12)
                    Text(homeMoney(total, currency: offer.currency))
                        .font(AppFont.bold(size: 20))
                        .foregroundStyle(AppColor.primary)
                }
            }
        }
    }

    @ViewBuilder private var merchant: some View {
        if let onMerchant, !offer.isRemote || (offer.store?.id ?? 0) > 0 {
            Button(action: onMerchant) {
                HStack(spacing: 6) {
                    Text(offer.displayMerchant)
                        .lineLimit(2)
                    Image(systemName: "chevron.forward")
                        .font(.system(size: 9, weight: .semibold))
                }
                .font(AppFont.medium(size: 13))
                .foregroundStyle(AppColor.primary)
            }
            .buttonStyle(.plain)
        } else {
            Text(offer.displayMerchant)
                .font(AppFont.medium(size: 13))
                .foregroundStyle(AppColor.primary)
        }
    }

    private var availability: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(offer.available ? AppColor.success : AppColor.secondaryText)
                .frame(width: 5, height: 5)
            Text(offer.availabilityStatus ?? homeText(offer.available ? "available" : "unavailable"))
                .font(AppFont.medium(size: 11))
        }
        .foregroundStyle(offer.available ? AppColor.success : AppColor.secondaryText)
        .padding(.horizontal, 9)
        .padding(.vertical, 5)
        .background(
            (offer.available ? AppColor.success : AppColor.secondaryText).opacity(0.08), in: Capsule()
        )
    }

    private func metadata(_ value: String, icon: HomeIcon) -> some View {
        HStack(alignment: .top, spacing: 8) {
            icon.view(14)
                .frame(width: 16, height: 18)
            Text(value)
                .fixedSize(horizontal: false, vertical: true)
        }
        .font(AppFont.regular(size: 12))
        .foregroundStyle(AppColor.secondaryText)
    }
}

extension HomeOffer {
    var checkoutAddress: String? {
        if !isRemote { return homeText("district") }
        let address = branch?.address?.trimmingCharacters(in: .whitespacesAndNewlines)
        return address?.isEmpty == false ? address : nil
    }

    var checkoutHours: String? {
        if !isRemote { return homeText("openingHours") }
        if let availableTimeText, !availableTimeText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return availableTimeText
        }
        guard let fromTime, !fromTime.isEmpty, let toTime, !toTime.isEmpty else { return nil }
        return "\(fromTime) – \(toTime)"
    }
}
