import SwiftUI

struct AccountRemoteDocument: View {
    let endpoint: AccountDocumentEndpoint
    @ObservedObject private var language = AppLanguageManager.shared
    @StateObject private var viewModel = AccountDocumentViewModel()
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if viewModel.loading {
                BrandLoaderView(size: 56)
                    .frame(maxWidth: .infinity)
            }
            if let error = viewModel.error {
                Text(error)
                    .foregroundStyle(AppColor.error)
                Button("accountAPI.retry".localized) {
                    Task {
                        await reload()
                    }
                }
            } else if let content = viewModel.content {
                if content.isEmpty {
                    Text("accountAPI.documentEmpty".localized)
                        .font(AppFont.body)
                        .foregroundStyle(AppColor.secondaryText)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)
                } else {
                    switch content {
                    case .text(let text):
                        Text(text)
                            .font(AppFont.body)
                            .textSelection(.enabled)
                            .lineSpacing(5)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    case .sections(let sections):
                        if sections.sections.isEmpty {
                            if let header = sections.header {
                                documentBlock(header, prominent: true)
                            }
                            ForEach(Array(sections.items.enumerated()), id: \.offset) { _, item in
                                documentBlock(item)
                            }
                            if let footer = sections.footer {
                                documentBlock(footer)
                            }
                        } else {
                            if let header = sections.header {
                                documentHeader(header)
                            }
                            if endpoint == .privacy {
                                CardContainer(padding: 0) {
                                    VStack(spacing: 0) {
                                        ForEach(Array(sections.sections.enumerated()), id: \.offset) { index, section in
                                            documentSection(section, index: index, showsIcon: false)
                                                .padding(16)
                                            if index < sections.sections.count - 1 {
                                                AppColor.border.frame(height: 1)
                                            }
                                        }
                                    }
                                }
                            } else {
                                ForEach(Array(sections.sections.enumerated()), id: \.offset) { index, section in
                                    CardContainer {
                                        documentSection(section, index: index, showsIcon: true)
                                    }
                                }
                            }
                            documentNotice(sections.footer)
                        }
                    }
                }
            }
        }
        .task(id: "\(endpoint.rawValue)-\(language.selectedLanguage)") {
            await reload()
        }
    }

    private func reload() async {
        await viewModel.load(endpoint: endpoint, language: language.apiLanguage)
    }

    private func documentHeader(_ header: AccountDocumentBlock) -> some View {
        CardContainer {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    if endpoint != .privacy && !header.title.isEmpty {
                        Text(header.title)
                            .font(AppFont.bold(size: 13))
                    }
                    if endpoint == .privacy, let lastUpdated = header.lastUpdated, !lastUpdated.isEmpty {
                        Text("\("settings.Last updated".localized): \(lastUpdated)")
                            .font(AppFont.medium(size: 11))
                            .foregroundStyle(AppColor.primary)
                    }
                    if !header.description.isEmpty {
                        Text(header.description)
                            .font(AppFont.regular(size: 11))
                            .foregroundStyle(AppColor.secondaryText)
                    }
                    if endpoint != .privacy, let lastUpdated = header.lastUpdated, !lastUpdated.isEmpty {
                        Text("\("settings.Last updated".localized): \(lastUpdated)")
                            .font(AppFont.medium(size: 10))
                            .foregroundStyle(AppColor.primary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .multilineTextAlignment(.leading)
                Image(endpoint == .privacy ? "lohDocumentPrivacyHero" : "lohDocumentTermsHero")
                    .frame(width: endpoint == .privacy ? 40 : 44, height: endpoint == .privacy ? 44 : 50)
                    .accessibilityHidden(true)
            }
        }
    }

    private func documentSection(_ section: AccountDocumentPointSection, index: Int, showsIcon: Bool) -> some View {
        HStack(alignment: .top, spacing: 12) {
            if showsIcon {
                Image(termsIcon(at: index))
                    .frame(width: 15, height: 15)
                    .frame(width: 36, height: 36)
                    .background(AppColor.accountCanvas, in: RoundedRectangle(cornerRadius: 12))
                    .accessibilityHidden(true)
            }
            VStack(alignment: .leading, spacing: 8) {
                Text("\(index + 1). \(section.title)")
                    .font(AppFont.bold(size: 14))
                    .foregroundStyle(AppColor.primary)
                ForEach(Array(section.points.enumerated()), id: \.offset) { _, point in
                    if !point.isEmpty {
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            if section.points.count > 1 {
                                Circle()
                                    .fill(AppColor.primary)
                                    .frame(width: 5, height: 5)
                            }
                            Text(point)
                                .font(AppFont.regular(size: 13))
                                .foregroundStyle(AppColor.secondaryText)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .multilineTextAlignment(.leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .textSelection(.enabled)
    }

    private func termsIcon(at index: Int) -> String {
        "lohDocumentTermsSection\(min(index + 1, 8))"
    }

    private func documentNotice(_ footer: AccountDocumentBlock?) -> some View {
        let fallback = endpoint == .privacy ? "settings.Privacy notice" : "settings.Terms notice"
        let text = [footer?.description, footer?.title]
            .compactMap { $0 }
            .first { !$0.isEmpty } ?? fallback.localized
        return HStack(spacing: 8) {
            Image(endpoint == .privacy ? "lohDocumentPrivacyFooter" : "lohDocumentTermsFooter")
                .frame(width: endpoint == .privacy ? 11 : 13, height: endpoint == .privacy ? 11 : 13)
                .accessibilityHidden(true)
            Text(text)
                .font(AppFont.regular(size: 10))
                .foregroundStyle(endpoint == .privacy ? AppColor.text : AppColor.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(endpoint == .privacy ? AppColor.primary : AppColor.surface,
                    in: RoundedRectangle(cornerRadius: 16))
    }

    @ViewBuilder private func documentBlock(_ block: AccountDocumentBlock, prominent: Bool = false) -> some View {
        if !block.isEmpty {
            CardContainer {
                VStack(alignment: .leading, spacing: 12) {
                    if let url = block.imageURL {
                        AsyncImage(url: url) { image in
                            image
                                .resizable()
                                .scaledToFit()
                        } placeholder: {
                            ProgressView()
                        }
                        .frame(width: prominent ? 64 : 40, height: prominent ? 64 : 40)
                        .accessibilityHidden(true)
                    }
                    if !block.title.isEmpty {
                        Text(block.title)
                            .font(AppFont.bold(size: prominent ? 18 : 15))
                    }
                    if !block.description.isEmpty {
                        Text(block.description)
                            .font(AppFont.regular(size: 14))
                            .foregroundStyle(AppColor.secondaryText)
                            .lineSpacing(5)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .textSelection(.enabled)
            }
        }
    }
}
