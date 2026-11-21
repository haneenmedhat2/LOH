import SwiftUI

struct HomeFilterButton: View {
    let count: Int
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            LOHAsset.filter.image
                .resizable()
                .scaledToFit()
                .frame(width: 20, height: 20)
                .frame(width: 44, height: 44)
                .background(AppColor.surface, in: RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(AppColor.border, lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.06), radius: 2, y: 1)
                .overlay(alignment: .topTrailing) {
                    if count > 0 {
                        Text(homeNumber(count))
                            .font(AppFont.bold(size: 10))
                            .foregroundStyle(.white)
                            .frame(width: 18, height: 18)
                            .background(AppColor.primary, in: Circle())
                            .offset(x: 3, y: -4)
                    }
                }
        }
        .environment(\.layoutDirection, .leftToRight)
        .buttonStyle(.plain)
        .accessibilityLabel(homeText("filterTitle"))
        .accessibilityValue(homeNumber(count))
    }
}
