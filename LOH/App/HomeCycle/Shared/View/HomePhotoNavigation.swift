import SwiftUI

/// Photo screens use the native back button and keep their actions in the trailing toolbar.
struct HomePhotoNavigation: ToolbarContent {
    let shareText: String
    var shareURL: URL? = nil
    var favorite = false
    var onFavorite: (() -> Void)? = nil
    var separateBackgrounds = false
    var body: some ToolbarContent {
        if #available(iOS 26.0, *), separateBackgrounds {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 4) {
                    favoriteButton
                    shareButton
                }
            }
            .sharedBackgroundVisibility(.hidden)
        } else {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                favoriteButton
                shareButton
            }
        }
    }

    @ViewBuilder private var favoriteButton: some View {
        if let onFavorite {
            HomeIconButton(
                icon: favorite ? .heartFilled : .heart,
                label: favorite ? "unfavorite" : "favorite",
                action: onFavorite
            )
        }
    }

    private var shareButton: some View {
        Group {
            if let shareURL {
                ShareLink(
                    item: shareURL,
                    subject: Text(shareText),
                    message: Text(shareText),
                    label: { shareLabel }
                )
            } else {
                ShareLink(item: shareText) { shareLabel }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(homeText("share"))
    }

    private var shareLabel: some View {
        HomeIcon.share.view(18)
            .frame(width: 40, height: 40)
            .background(AppColor.surface, in: Circle())
            .frame(width: 44, height: 44)
    }
}
