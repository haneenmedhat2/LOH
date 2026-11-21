import SwiftUI

struct HomeMerchantInfo: View {
    let merchant: HomeMerchant
    let isFollowing: Bool
    let isUpdatingFollow: Bool
    let canFollow: Bool
    let onFollow: () -> Void
    @State private var expanded = false
    @State private var collapsedAboutHeight: CGFloat = 0
    @State private var fullAboutHeight: CGFloat = 0

    private var locationSummary: String {
        guard merchant.location?.hasCoordinates == true else { return "" }
        return [merchant.distance?.displayText, merchant.locationText?.nonEmpty ?? merchant.address?.nonEmpty]
            .compactMap { $0?.nonEmpty }
            .joined(separator: " · ")
    }

    var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 6) {
                HStack(spacing: 8) {
                    Text(merchant.name)
                        .font(AppFont.extraBold(size: 22))
                    if merchant.isVerified { HomeIcon.verified.view(20) }
                }
                .multilineTextAlignment(.center)
                if let type = merchant.storeType?.nonEmpty {
                    Text(type)
                        .font(AppFont.regular(size: 14))
                        .foregroundStyle(AppColor.secondaryText)
                }
                if let rating = merchant.rating {
                    HStack(spacing: 4) {
                        HomeIcon.star.view(14)
                        Text(homeNumber(rating))
                            .font(AppFont.bold(size: 14))
                        if let text = merchant.ratingText?.nonEmpty {
                            Text(text)
                                .font(AppFont.regular(size: 13))
                                .foregroundStyle(AppColor.mutedText)
                        } else if let count = merchant.ratingCount {
                            Text(homeFormat("reviewsFormat", homeNumber(count)))
                                .font(AppFont.regular(size: 13))
                                .foregroundStyle(AppColor.mutedText)
                        }
                    }
                }
                if !locationSummary.isEmpty {
                    HStack(spacing: 4) {
                        HomeIcon.pin.view(14)
                        Text(locationSummary)
                            .font(AppFont.regular(size: 13))
                            .foregroundStyle(AppColor.secondaryText)
                    }
                    .padding(.top, 4)
                }
            }
            HStack(spacing: 12) {
                Button(action: onFollow) {
                    HStack(spacing: 8) {
                        if isUpdatingFollow {
                            BrandLoaderView(size: 24)
                        } else {
                            (isFollowing ? HomeIcon.heartFilled : .heart).view(18)
                        }
                        Text(homeText(isFollowing ? "following" : "follow"))
                            .font(AppFont.medium(size: 14))
                    }
                    .frame(maxWidth: .infinity, minHeight: 47)
                    .background(AppColor.surface, in: RoundedRectangle(cornerRadius: 16))
                    .overlay {
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(AppColor.border)
                    }
                }
                .buttonStyle(.plain)
                .disabled(!canFollow || isUpdatingFollow)
                if merchant.location?.hasCoordinates == true, let url = merchant.location?.url {
                    HomeMerchantDirections(url: url, title: merchant.location?.directionsLabel)
                }
            }
            statistics
            if let about = merchant.about?.nonEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text(homeText("aboutMerchant"))
                        .font(AppFont.bold(size: 16))
                    aboutText(about)
                        .lineLimit(expanded ? nil : 2)
                        .background {
                            aboutText(about)
                                .lineLimit(2)
                                .background {
                                    GeometryReader { geometry in
                                        Color.clear.preference(
                                            key: CollapsedAboutHeightKey.self, value: geometry.size.height)
                                    }
                                }
                                .hidden()
                        }
                        .background {
                            aboutText(about)
                                .fixedSize(horizontal: false, vertical: true)
                                .background {
                                    GeometryReader { geometry in
                                        Color.clear.preference(
                                            key: FullAboutHeightKey.self, value: geometry.size.height)
                                    }
                                }
                                .hidden()
                        }
                        .onPreferenceChange(CollapsedAboutHeightKey.self) { collapsedAboutHeight = $0 }
                        .onPreferenceChange(FullAboutHeightKey.self) { fullAboutHeight = $0 }
                    if fullAboutHeight > collapsedAboutHeight + 1 {
                        Button(homeText(expanded ? "less" : "more")) { expanded.toggle() }
                            .font(AppFont.medium(size: 13))
                            .foregroundStyle(AppColor.primary)
                            .frame(minHeight: 28)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private func aboutText(_ text: String) -> some View {
        Text(text)
            .font(AppFont.regular(size: 14))
            .foregroundStyle(AppColor.secondaryText)
            .lineSpacing(6)
    }

    private var statistics: some View {
        HStack(spacing: 0) {
            statistic(homeNumber(merchant.stats.offersCount ?? merchant.offers.count), "availableOffers", primary: true)
            if let distance = merchant.stats.distance ?? merchant.distance {
                Divider().frame(height: 38)
                statistic(distance.displayText, "distance")
            }
            if let rating = merchant.stats.rating ?? merchant.rating {
                Divider().frame(height: 38)
                statistic(homeNumber(rating), "rating")
            }
        }
        .fixedSize(horizontal: false, vertical: true)
        .background(AppColor.surface, in: RoundedRectangle(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(AppColor.border.opacity(0.5))
        }
    }

    private func statistic(_ value: String, _ title: String, primary: Bool = false) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(AppFont.extraBold(size: 20))
                .foregroundStyle(primary ? AppColor.primary : AppColor.text)
            Text(homeText(title))
                .font(AppFont.regular(size: 12))
                .foregroundStyle(AppColor.secondaryText)
        }
        .multilineTextAlignment(.center)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, minHeight: 64)
    }
}

private struct CollapsedAboutHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = nextValue() }
}

private struct FullAboutHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = nextValue() }
}

extension HomeMerchantDistance {
    var displayText: String {
        switch self {
        case .kilometers(let value): return homeDistance(value)
        case .text(let text): return text
        }
    }
}

private extension String {
    var nonEmpty: String? {
        let value = trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }
}
