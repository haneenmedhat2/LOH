import SwiftUI
import Kingfisher

struct AccountAvatar: View {
    let image: UIImage?
    var url: String? = nil
    var revision: UUID? = nil
    var showsBorder = false
    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
            } else if let url = url.flatMap(URL.init(string:)), ["https", "http"].contains(url.scheme ?? "") {
                KFImage(url)
                    .forceRefresh()
                    .requestModifier(
                        AnyModifier { request in
                            var request = request
                            request.cachePolicy = .reloadIgnoringLocalCacheData
                            return request
                        }
                    )
                    .placeholder {
                        placeholder
                    }
                    .resizable()
                    .id("\(url.absoluteString)-\(revision?.uuidString ?? "cached")")
            } else {
                placeholder
            }
        }
        .scaledToFill()
        .frame(width: 80, height: 80)
        .clipShape(Circle())
        .overlay {
            if showsBorder {
                Circle()
                    .stroke(AppColor.border, lineWidth: 1.5)
            }
        }
        .overlay(alignment: .bottomTrailing) {
            profileIcon(.accountCamera, size: 13)
                .frame(width: 28, height: 28)
                .background(AppColor.primary, in: Circle())
        }
        .accessibilityHidden(true)
    }

    private var placeholder: some View {
        ZStack {
            Circle()
                .fill(AppColor.disabledSurface)
            Image(systemName: "person.fill")
                .font(.system(size: 32))
                .foregroundStyle(AppColor.mutedText)
        }
        .frame(width: 80, height: 80)
    }
}

/// Figma icons are authored for Arabic; only directional arrows are mirrored in English.
struct ProfileDirectionalIcon: View {
    let asset: LOHAsset
    var size: CGFloat = 18
    @Environment(\.layoutDirection) private var direction
    var body: some View {
        profileIcon(asset, size: size)
            .scaleEffect(x: direction == .leftToRight ? -1 : 1, y: 1)
    }
}

func profileIcon(_ asset: LOHAsset, size: CGFloat) -> some View {
    asset.image
        .resizable()
        .scaledToFit()
        .frame(width: size, height: size)
        .accessibilityHidden(true)
}

var profileDivider: some View {
    Color(white: 0.96)
        .frame(height: 1)
}
