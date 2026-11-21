import SwiftUI

struct HomeBannerCarousel: View {
    let banners: [HomeBanner]
    @Binding var selection: Int
    let action: (HomeBanner) -> (() -> Void)?
    @ScaledMetric(relativeTo: .title2) private var height: CGFloat = 180

    var body: some View {
        TabView(selection: $selection) {
            ForEach(Array(banners.enumerated()), id: \.element.id) { index, item in
                HomeBannerCard(
                    image: item.image ?? "", title: item.title,
                    description: item.description, action: action(item)
                )
                .tag(index)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .frame(height: height)
        .overlay(alignment: .bottom) {
            if banners.count > 1 {
                HStack(spacing: AppSpacing.xs) {
                    ForEach(banners.indices, id: \.self) { index in
                        Capsule()
                            .fill(AppColor.surface.opacity(index == selection ? 1 : 0.6))
                            .frame(width: index == selection ? 16 : 6, height: 6)
                    }
                }
                .padding(.bottom, AppSpacing.medium)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.standard))
    }
}

struct HomeBannerCard: View {
    let image: String
    let title: String?
    let description: String?
    let action: (() -> Void)?

    private var heading: String? { nonempty(title) }
    private var subtitle: String? { nonempty(description) }
    private var showsAction: Bool { action != nil && (heading != nil || subtitle != nil) }
    private var accessibilityLabel: String {
        let text = [heading, subtitle, showsAction ? homeText("exploreNow") : nil].compactMap { $0 }
            .joined(separator: ", ")
        return text.isEmpty ? homeText("offerDetails") : text
    }

    var body: some View {
        Button {
            action?()
        } label: {
            ZStack {
                // Extend the artwork softly behind any letterboxing, without cropping the foreground.
                HomePhoto(asset: image)
                    .blur(radius: 16)
                    .overlay(Color.black.opacity(0.2))
                HomePhoto(asset: image, contentMode: .fit)
                LinearGradient(
                    colors: [.black.opacity(0.45), .black.opacity(0.12)],
                    startPoint: .leading, endPoint: .trailing)
                VStack(alignment: .leading, spacing: 0) {
                    if let heading {
                        Text(heading)
                            .font(AppFont.black(size: 28))
                            .foregroundStyle(AppColor.surface)
                            .lineLimit(2)
                            .minimumScaleFactor(0.75)
                    }
                    if let subtitle {
                        Text(subtitle)
                            .font(AppFont.regular(size: 13))
                            .foregroundStyle(AppColor.surface)
                            .lineLimit(2)
                            .minimumScaleFactor(0.85)
                            .padding(.top, AppSpacing.xxs)
                    }
                    if showsAction {
                        Text(homeText("exploreNow"))
                            .font(AppFont.bold(size: 12))
                            .foregroundStyle(AppColor.text)
                            .padding(.horizontal, AppSpacing.standard)
                            .padding(.vertical, AppSpacing.xs)
                            .frame(minWidth: 108, minHeight: 30)
                            .background(AppColor.surface, in: RoundedRectangle(cornerRadius: AppRadius.small))
                            .padding(.top, AppSpacing.medium)
                    }
                }
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                .padding(.horizontal, AppSpacing.auth)
                .padding(.top, AppSpacing.standard)
                .padding(.bottom, 28)
            }
            .clipped()
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(action == nil)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
    }
    private func nonempty(_ value: String?) -> String? {
        guard let text = value?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty else {
            return nil
        }
        return text
    }
}
