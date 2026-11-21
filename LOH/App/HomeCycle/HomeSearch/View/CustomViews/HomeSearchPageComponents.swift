import SwiftUI

struct HomeSearchRecentChip: View {
    let title: String
    let search: () -> Void
    let remove: () -> Void

    var body: some View {
        HStack(spacing: 4) {
            Button(action: search) {
                HStack(spacing: 7) {
                    HomeIcon.history.view(14)
                    Text(title)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            Button(action: remove) {
                HomeIcon.close.view(13, color: AppColor.mutedText)
                    .frame(width: 28, height: 40)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(homeText("clearSearch") + " " + title)
        }
        .font(AppFont.regular(size: 14))
        .padding(.horizontal, 8)
        .frame(height: 44)
        .background(AppColor.surface, in: RoundedRectangle(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(AppColor.border.opacity(0.7))
        }
    }
}

struct HomeSearchSuggestionTile: View {
    let title: String
    let image: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            GeometryReader { geometry in
                Image(image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .overlay(Color.black.opacity(0.28))
                    .overlay {
                        Text(title)
                            .font(AppFont.bold(size: 14))
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.center)
                            .padding(8)
                    }
                    .clipped()
            }
            .frame(height: 96)
        }
        .buttonStyle(.plain)
    }
}

struct HomeSearchTrendingRow: View {
    let rank: Int
    let keyword: String
    let showsDivider: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Text(homeNumber(rank))
                    .font(AppFont.bold(size: 14))
                    .foregroundStyle(rank == 1 ? AppColor.primary : AppColor.mutedText)
                    .frame(width: 20)
                Text(keyword)
                    .font(AppFont.regular(size: 15))
                    .foregroundStyle(AppColor.text)
                Spacer(minLength: 0)
                HomeIcon.trend.view(18, color: rank == 1 ? AppColor.primary : AppColor.mutedText)
            }
            .frame(height: 52)
            .contentShape(Rectangle())
            .overlay(alignment: .bottom) {
                if showsDivider {
                    AppColor.border.opacity(0.55).frame(height: 1)
                }
            }
        }
        .buttonStyle(.plain)
    }
}
