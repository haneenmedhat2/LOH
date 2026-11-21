import SwiftUI

/// Prefer the QR supplied by the backend. Its exact voucher number remains a
/// local rendering fallback when the remote image cannot be loaded.
struct PurchaseQRImageView: View {
    let url: URL?
    let fallback: CGImage?
    @State private var retryID = UUID()

    var body: some View {
        Group {
            if let url {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        qrImage(image)
                    case .failure:
                        fallbackContent
                    case .empty:
                        ProgressView()
                    @unknown default:
                        fallbackContent
                    }
                }
                .id(retryID)
            } else {
                fallbackContent
            }
        }
        .frame(width: 200, height: 200)
        .padding(12)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(.white)
                .shadow(color: .black.opacity(0.08), radius: 2, y: 1)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(AppColor.border.opacity(0.55), lineWidth: 1)
        }
        .accessibilityLabel(homeText("usageCode"))
    }

    @ViewBuilder private var fallbackContent: some View {
        if let fallback {
            qrImage(Image(decorative: fallback, scale: 1, orientation: .up))
        } else if url != nil {
            Button("api.retry".localized) {
                retryID = UUID()
            }
            .font(AppFont.medium(size: 14))
            .foregroundStyle(AppColor.primary)
        } else {
            ProgressView()
        }
    }

    private func qrImage(_ image: Image) -> some View {
        image
            .interpolation(.none)
            .resizable()
            .scaledToFit()
    }
}
