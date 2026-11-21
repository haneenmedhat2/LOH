import SwiftUI

/// Presentation of the security-privacy response in Figma's dedicated settings layout.
struct AccountSecurityContentView: View {
    let content: AccountDocumentContent
    let openPrivacyPolicy: () -> Void
    @Environment(\.layoutDirection) private var direction

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            if content.isEmpty {
                Text("accountAPI.documentEmpty".localized)
                    .font(AppFont.body)
                    .foregroundStyle(AppColor.secondaryText)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
                privacyPolicy
            } else {
                switch content {
                case .sections(let sections):
                    if let header = sections.header, !header.isEmpty {
                        hero(header)
                    }
                    if !sections.items.isEmpty {
                        Text("more.How we protect your data".localized)
                            .font(AppFont.bold(size: 12))
                            .foregroundStyle(AppColor.secondaryText)
                            .frame(minHeight: 18)
                            .padding(.horizontal, 4)
                        protectionCard(sections.items)
                    }
                    privacyPolicy
                    if let footer = sections.footer, !footer.isEmpty {
                        CardContainer(padding: 0) {
                            informationRow(footer, fallbackIcon: "Secure", background: AppColor.accentSurface)
                        }
                    }
                case .text(let text):
                    CardContainer {
                        Text(text)
                            .font(AppFont.body)
                            .lineSpacing(5)
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    privacyPolicy
                }
            }
        }
    }

    private func hero(_ header: AccountDocumentBlock) -> some View {
        CardContainer(padding: 0) {
            HStack(spacing: AppSpacing.medium) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(highlightedTitle(header.title))
                        .font(AppFont.black(size: 15))
                        .frame(minHeight: 22.5, alignment: .leading)
                    Text(header.description)
                        .font(AppFont.regular(size: 11))
                        .foregroundStyle(AppColor.secondaryText)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .multilineTextAlignment(.leading)
                AccountSecurityImage(url: header.imageURL, fallback: "SecurityHero", width: 52, height: 58)
                    .frame(width: 56, height: 58)
            }
            .padding(.horizontal, AppSpacing.standard)
            .padding(.vertical, AppSpacing.medium)
        }
    }

    private func protectionCard(_ items: [AccountDocumentBlock]) -> some View {
        CardContainer(padding: 0) {
            VStack(spacing: 0) {
                ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                    informationRow(item, fallbackIcon: fallbackIcon(at: index), background: AppColor.accountCanvas)
                    if index < items.count - 1 {
                        Rectangle()
                            .fill(Color(red: 242 / 255, green: 242 / 255, blue: 247 / 255))
                            .frame(height: 1)
                            .accessibilityHidden(true)
                    }
                }
            }
        }
    }

    private func informationRow(_ block: AccountDocumentBlock, fallbackIcon: String, background: Color) -> some View {
        HStack(spacing: AppSpacing.medium) {
            AccountSecurityImage(url: block.imageURL, fallback: fallbackIcon, width: 16, height: 16)
                .frame(width: 32, height: 32)
                .background(background, in: RoundedRectangle(cornerRadius: AppRadius.medium))
            labels(title: block.title, subtitle: block.description)
        }
        .padding(.horizontal, AppSpacing.standard)
        .padding(.vertical, AppSpacing.medium)
        .accessibilityElement(children: .combine)
    }

    private var privacyPolicy: some View {
        Button(action: openPrivacyPolicy) {
            CardContainer(padding: 0) {
                HStack(spacing: AppSpacing.medium) {
                    SettingsIcon(name: "PolicyDocument", width: 16)
                        .frame(width: 32, height: 32)
                        .background(AppColor.accentSurface, in: RoundedRectangle(cornerRadius: AppRadius.medium))
                    labels(title: "more.Privacy policy".localized, subtitle: "settings.Policy subtitle".localized)
                    SettingsIcon(name: "PolicyArrow", width: 16)
                        .scaleEffect(x: direction == .rightToLeft ? 1 : -1, y: 1)
                }
                .padding(.horizontal, AppSpacing.standard)
                .padding(.vertical, AppSpacing.medium)
                .contentShape(Rectangle())
            }
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("security-privacy-policy")
    }

    private func labels(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            if !title.isEmpty {
                Text(title)
                    .font(AppFont.bold(size: 13))
                    .foregroundStyle(AppColor.text)
                    .frame(minHeight: 19.5, alignment: .leading)
            }
            if !subtitle.isEmpty {
                Text(subtitle)
                    .font(AppFont.regular(size: 11))
                    .foregroundStyle(AppColor.secondaryText)
                    .lineSpacing(3)
                    .frame(minHeight: 16.5, alignment: .leading)
            }
        }
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity, alignment: .leading)
        .multilineTextAlignment(.leading)
    }

    private func highlightedTitle(_ title: String) -> AttributedString {
        var result = AttributedString(title)
        if let range = result.range(of: "settings.Our priority".localized, options: .caseInsensitive) {
            result[range].foregroundColor = AppColor.primary
        }
        return result
    }

    private func fallbackIcon(at index: Int) -> String {
        let icons = ["SecurityLock", "Private", "Person", "Card"]
        return icons.indices.contains(index) ? icons[index] : "Secure"
    }
}

/// API artwork takes precedence; the exported Figma asset remains visible while loading or on failure.
private struct AccountSecurityImage: View {
    let url: URL?
    let fallback: String
    let width: CGFloat
    let height: CGFloat

    var body: some View {
        Group {
            if let url {
                AsyncImage(url: url) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .scaledToFit()
                    } else {
                        SettingsIcon(name: fallback, width: width, height: height)
                    }
                }
            } else {
                SettingsIcon(name: fallback, width: width, height: height)
            }
        }
        .frame(width: width, height: height)
        .accessibilityHidden(true)
    }
}
