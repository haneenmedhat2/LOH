import SwiftUI
import UIKit

struct HomePhoto: View {
    let asset: String
    var contentMode: ContentMode = .fill
    private var source: String { asset.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var remoteURL: URL? {
        guard let url = URL(string: source),
            let scheme = url.scheme?.lowercased(), ["https", "http"].contains(scheme),
            let host = url.host, !host.isEmpty
        else {
            return nil
        }
        return url
    }

    var body: some View {
        GeometryReader { geometry in
            Group {
                if let url = remoteURL {
                    AsyncImage(url: url) { phase in
                        if let image = phase.image {
                            image
                                .resizable()
                                .aspectRatio(contentMode: contentMode)
                        } else {
                            placeholder(in: geometry.size)
                        }
                    }
                } else if !source.isEmpty, let image = UIImage(named: source) {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: contentMode)
                } else {
                    placeholder(in: geometry.size)
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .clipped()
        }
        .accessibilityHidden(true)
    }

    private func placeholder(in size: CGSize) -> some View {
        AppColor.canvas
            .overlay {
                LOHAsset.logo.image
                    .resizable()
                    .scaledToFit()
                    .frame(width: min(120, size.width * 0.6), height: min(56, size.height * 0.6))
            }
    }
}
