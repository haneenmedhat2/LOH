import SwiftUI

struct HomeDirectionsButton: View {
    let merchant: String
    var compact = false
    @Environment(\.openURL) private var openURL
    var body: some View {
        Button {
            var url = URLComponents(string: "https://maps.apple.com/")!
            url.queryItems = [URLQueryItem(name: "q", value: "\(merchant), Riyadh, Saudi Arabia")]
            if let url = url.url {
                openURL(url)
            }
        } label: {
            HStack(spacing: 8) {
                HomeIcon.directions.view(compact ? 14 : 18)
                Text(homeText("directions"))
                    .font(AppFont.medium(size: compact ? 12 : 14))
            }
            .frame(maxWidth: compact ? nil : .infinity, minHeight: compact ? 38 : 46)
            .padding(.horizontal, compact ? 8 : 0)
            .background(AppColor.surface, in: RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(AppColor.border, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}
