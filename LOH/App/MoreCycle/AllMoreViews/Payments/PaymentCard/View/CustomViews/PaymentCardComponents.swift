import SwiftUI

struct PaymentCardsIllustration: View {
    var body: some View {
        ZStack(alignment: .topLeading) {
            // Export dimensions include the Figma drop shadows around each card.
            LOHAsset.paymentBlackCard.image
                .resizable()
                .frame(width: 70, height: 53)
                .offset(x: -5, y: 24)
            LOHAsset.paymentGoldCard.image
                .resizable()
                .frame(width: 69, height: 51)
                .offset(x: 25, y: -2)
        }
        .frame(width: 80, height: 65)
        .environment(\.layoutDirection, .leftToRight)
        .accessibilityHidden(true)
    }
}
struct PaymentSavedCardRow: View {
    let card: AccountCard
    let action: () -> Void
    var body: some View {
        CardContainer(padding: 16, cornerRadius: 16, border: Color(white: 0.94)) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top, spacing: 12) {
                    PaymentBrandLogo(brand: card.brand)
                    Spacer(minLength: 0)
                    VStack(alignment: .leading, spacing: 4) {
                        ViewThatFits(in: .horizontal) {
                            HStack(spacing: 8) {
                                cardTitle
                                defaultBadge
                            }
                            .fixedSize(horizontal: true, vertical: false)
                            VStack(alignment: .leading, spacing: 6) {
                                cardTitle
                                defaultBadge
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .frame(minHeight: 23, alignment: .leading)
                        Text("••• ••• ••• " + card.lastFour)
                            .font(AppFont.regular(size: 13))
                            .foregroundStyle(AppColor.secondaryText)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                            .environment(\.layoutDirection, .leftToRight)
                            .frame(maxWidth: .infinity, minHeight: 20, alignment: .leading)
                    }
                    .layoutPriority(1)
                    Spacer(minLength: 0)
                    Button(action: action) {
                        profileIcon(.paymentMore, size: 18)
                            .padding(13)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .frame(width: 18, height: 18)
                    .accessibilityLabel("more.Card options".localized)
                    .accessibilityValue(card.paymentTitle)
                }
                if !card.expiry.isEmpty {
                    Text(card.expiry)
                        .font(AppFont.regular(size: 12))
                        .foregroundStyle(AppColor.secondaryText)
                        .environment(\.layoutDirection, .leftToRight)
                        .frame(maxWidth: .infinity, minHeight: 18, alignment: .leading)
                        .accessibilityLabel(String(format: "payments.expiresFormat".localized, card.expiry))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    private var cardTitle: some View {
        Text(card.paymentTitle)
            .font(AppFont.bold(size: 15))
            .lineLimit(2)
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
            .frame(minHeight: 23, alignment: .leading)
    }
    @ViewBuilder private var defaultBadge: some View {
        if card.isDefault {
            Text("more.Default card".localized)
                .font(AppFont.regular(size: 11))
                .foregroundStyle(AppColor.success)
                .lineLimit(1)
                .frame(minHeight: 15)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .overlay(
                    Capsule()
                        .strokeBorder(AppColor.success)
                )
                .fixedSize()
        }
    }
}

struct PaymentBrandLogo: View {
    enum Size {
        case savedCard, compact
    }

    let brand: String
    var size: Size = .savedCard

    var body: some View {
        Group {
            switch brand.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
            case "visa":
                LOHAsset.visa.image
                    .renderingMode(.original)
                    .resizable()
                    .scaledToFit()
                    .frame(width: size == .compact ? 29 : 44, height: size == .compact ? 18 : 30)
            case "mastercard", "master":
                LOHAsset.mastercard.image
                    .renderingMode(.original)
                    .resizable()
                    .scaledToFit()
                    .frame(width: size == .compact ? 30 : 46, height: size == .compact ? 18 : 28)
            case "mada":
                LOHAsset.mada.image
                    .renderingMode(.original)
                    .resizable()
                    .scaledToFit()
                    .frame(width: size == .compact ? 30 : 41, height: size == .compact ? 16 : 22)
            default:
                profileIcon(.paymentFormCard, size: 16)
                    .frame(width: size == .compact ? 29 : 44, height: size == .compact ? 18 : 30)
            }
        }
        .environment(\.layoutDirection, .leftToRight)
        .accessibilityHidden(true)
    }
}

extension AccountCard {
    var paymentTitle: String {
        if !nickname.isEmpty {
            return nickname
        }
        switch brand {
        case "visa": return "more.Visa".localized
        case "mastercard": return "more.Mastercard".localized
        case "mada": return "home.mada".localized
        default: return "more.Card".localized
        }
    }
}

