import SwiftUI

struct PurchaseRatingStars: View {
    let value: Double
    var size: CGFloat = 32
    var spacing: CGFloat = 0
    var onSelect: ((Int) -> Void)?

    var body: some View {
        Group {
            if onSelect == nil {
                stars
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(homeText("rating"))
                    .accessibilityValue(homeNumber(value, decimals: 1))
            } else {
                stars
            }
        }
        .environment(\.layoutDirection, .leftToRight)
    }

    private var stars: some View {
        HStack(spacing: spacing) {
            ForEach(1...5, id: \.self) { star in
                if let onSelect {
                    Button {
                        onSelect(star)
                    } label: {
                        starImage(star)
                            .frame(minWidth: 44, minHeight: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(homeFormat("ratingStarsFormat", homeNumber(star)))
                    .accessibilityAddTraits(Int(value) == star ? .isSelected : [])
                } else {
                    starImage(star)
                        .frame(minWidth: 40, minHeight: 44)
                }
            }
        }
    }

    private func starImage(_ star: Int) -> some View {
        Image("lohPurchasesStarOutline")
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .overlay(alignment: .leading) {
                Image("lohPurchasesStarFilled")
                    .resizable()
                    .scaledToFit()
                    .frame(width: size, height: size)
                    .mask(alignment: .leading) {
                        Rectangle()
                            .frame(width: size * min(1, max(0, value - Double(star - 1))))
                    }
            }
    }
}
