import SwiftUI

struct OnboardingPageView: View {
    let page: OnboardingPage

    var body: some View {
        GeometryReader { geometry in
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    AsyncImage(url: page.imageURL) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFit()
                        case .empty:
                            if page.imageURL == nil {
                                LOHAsset.logo.image
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 100)
                            } else {
                                ProgressView()
                            }
                        case .failure:
                            LOHAsset.logo.image
                                .resizable()
                                .scaledToFit()
                                .frame(width: 100)
                        @unknown default: EmptyView()
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: artworkHeight(in: geometry.size))
                    .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: AppSpacing.medium) {
                        Text(page.title)
                            .foregroundColor(AppColor.text)
                            .font(
                                AppFont
                                    .font(.extraBold, size: 22, relativeTo: .title2)
                            )
                            .fixedSize(horizontal: false, vertical: true)
                            .accessibilityAddTraits(.isHeader)
                        Text(page.message)
                            .font(AppFont.regular(size: 14))
                            .foregroundStyle(AppColor.secondaryText)
                            .lineSpacing(4)
                            .fixedSize(horizontal: false, vertical: true)
                        if !page.tags.isEmpty {
                            LazyVGrid(
                                columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())],
                                alignment: .leading,
                                spacing: AppSpacing.medium
                            ) {
                                ForEach(page.tags) { tag in
                                    onboardingTag(tag)
                                }
                            }
                            .padding(.top, AppSpacing.standard)
                        }
                    }
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, minHeight: 74, alignment: .topLeading)
                    .padding(.top, 10)
                    .padding(.horizontal, AppSpacing.auth)
                }
                .frame(minHeight: geometry.size.height, alignment: .top)
            }
        }
    }

    private func artworkHeight(in size: CGSize) -> CGFloat {
        // Preserve each illustration's aspect ratio; allow copy to scroll at larger text sizes.
        let naturalHeight = size.width * 1.08
        return min(naturalHeight, max(180, size.height - 160))
    }

    private func onboardingTag(_ tag: OnboardingTag) -> some View {
        HStack(spacing: AppSpacing.small) {
            AsyncImage(url: tag.iconURL) { phase in
                if let image = phase.image {
                    image
                        .resizable()
                        .scaledToFit()
                } else if tag.iconURL != nil && phase.error == nil {
                    ProgressView()
                } else {
                    Image(systemName: "tag")
                        .resizable()
                        .scaledToFit()
                        .foregroundStyle(AppColor.primary)
                }
            }
            .frame(width: 20, height: 20)
            .accessibilityHidden(true)

            Text(tag.name)
                .font(AppFont.medium(size: 14))
                .foregroundStyle(AppColor.text)
                .fixedSize(horizontal: false, vertical: true)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 44)
        .padding(.horizontal, AppSpacing.medium)
        .background(AppColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.small))
        .overlay {
            RoundedRectangle(cornerRadius: AppRadius.small)
                .stroke(AppColor.border, lineWidth: 1.5)
        }
        .accessibilityElement(children: .combine)
    }
}
