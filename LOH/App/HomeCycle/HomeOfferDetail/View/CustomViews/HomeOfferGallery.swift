import SwiftUI

struct HomeOfferGallery: View {
    let offer: HomeOffer
    @Environment(\.layoutDirection) private var layoutDirection
    @State private var selection = 0
    @State private var showsViewer = false

    private var images: [String] {
        offer.images.isEmpty ? [offer.asset] : offer.images.map(\.image)
    }

    var body: some View {
        Group {
            if images.count > 1 {
                TabView(selection: $selection) {
                    ForEach(Array(images.enumerated()), id: \.offset) { index, image in
                        photo(image, index: index)
                            .ignoresSafeArea(.container, edges: .top)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .ignoresSafeArea(.container, edges: .top)
            } else {
                photo(images[0], index: 0)
                    .ignoresSafeArea(.container, edges: .top)
            }
        }
        .overlay(alignment: .bottomTrailing) {
            Text("\(min(selection + 1, images.count))/\(images.count)")
                .font(AppFont.regular(size: 12))
                .foregroundStyle(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(.black.opacity(0.5), in: Capsule())
                .environment(\.layoutDirection, .leftToRight)
                .padding(16)
                .allowsHitTesting(false)
        }
        .clipped()
        .onChange(of: images) { _ in
            selection = 0
        }
        .fullScreenCover(isPresented: $showsViewer) {
            FullScreenImageViewer(urls: images, startIndex: selection)
                .environment(\.layoutDirection, layoutDirection)
                .logScreen("FullScreenImageViewer")
        }
    }

    private func photo(_ image: String, index: Int) -> some View {
        Button {
            selection = index
            showsViewer = true
        } label: {
            HomePhoto(asset: image)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(homeText("viewPhoto"))
    }
}
