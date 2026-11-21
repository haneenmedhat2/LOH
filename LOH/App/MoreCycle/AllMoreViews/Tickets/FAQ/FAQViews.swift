import SwiftUI

struct FAQListView: View {
    @EnvironmentObject private var coordinator: MoreCoordinator
    @ObservedObject private var language = AppLanguageManager.shared
    @StateObject private var model = FAQListViewModel()

    var body: some View {
        AccountPage(
            title: model.data?.header?.title ?? "faq.title".localized,
            hidesTabBar: true,
            headerHeight: 60,
            contentSpacing: 16,
            onRefresh: { await model.load(language: language.apiLanguage) }
        ) {
            if let header = model.data?.header {
                HStack(spacing: 14) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(header.cardTitle)
                            .font(AppFont.bold(size: 17))
                        Text(header.description)
                            .font(AppFont.regular(size: 13))
                            .foregroundStyle(AppColor.secondaryText)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    FAQSymbol(name: "questionmark.circle", size: 54)
                }
                .padding(16)
                .background(AppColor.surface, in: RoundedRectangle(cornerRadius: 18))
            }

            if let categories = model.data?.categories, !categories.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        categoryButton(id: nil, title: "faq.all".localized)
                        ForEach(categories) { category in
                            categoryButton(id: category.id, title: category.title)
                        }
                    }
                }
            }

            if model.loading && model.data == nil {
                BrandLoaderView(size: 56)
                    .frame(maxWidth: .infinity)
                    .padding(32)
            }
            if let error = model.error {
                HomeAPIError(message: error) {
                    Task { await model.load(language: language.apiLanguage) }
                }
            }
            if model.data != nil {
                Text("faq.popular".localized)
                    .font(AppFont.bold(size: 16))
                    .frame(maxWidth: .infinity, alignment: .leading)
                if model.questions.isEmpty {
                    Text("faq.empty".localized)
                        .font(AppFont.regular(size: 14))
                        .foregroundStyle(AppColor.secondaryText)
                        .frame(maxWidth: .infinity)
                        .padding(32)
                } else {
                    VStack(spacing: 0) {
                        ForEach(model.questions) { question in
                            Button {
                                coordinator.show(.faqDetail(question.id))
                            } label: {
                                HStack(spacing: 12) {
                                    FAQSymbol(name: question.category?.icon, size: 38)
                                    Text(question.question)
                                        .font(AppFont.medium(size: 14))
                                        .foregroundStyle(AppColor.text)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    Image(systemName: "chevron.forward")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundStyle(AppColor.secondaryText)
                                }
                                .padding(.horizontal, 16)
                                .frame(minHeight: 64)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            if question.id != model.questions.last?.id {
                                Divider().padding(.leading, 64)
                            }
                        }
                    }
                    .background(AppColor.surface, in: RoundedRectangle(cornerRadius: 16))
                }
            }
        }
        .task(id: language.apiLanguage) {
            await model.load(language: language.apiLanguage)
        }
    }

    private func categoryButton(id: Int?, title: String) -> some View {
        let selected = model.selectedCategoryID == id
        return Button {
            model.selectedCategoryID = id
        } label: {
            Text(title)
                .font(AppFont.medium(size: 13))
                .foregroundStyle(selected ? AppColor.primary : AppColor.secondaryText)
                .padding(.horizontal, 14)
                .frame(height: 38)
                .background(selected ? AppColor.accentSurface : AppColor.surface, in: Capsule())
                .overlay(Capsule().strokeBorder(selected ? AppColor.primary : AppColor.border))
        }
        .buttonStyle(.plain)
    }
}

struct FAQDetailView: View {
    let id: Int
    @ObservedObject private var language = AppLanguageManager.shared
    @StateObject private var model = FAQDetailViewModel()

    var body: some View {
        AccountPage(
            title: "faq.title".localized,
            hidesTabBar: true,
            headerHeight: 60,
            contentSpacing: 12,
            onRefresh: { await model.load(id: id, language: language.apiLanguage) }
        ) {
            if model.loading && model.question == nil {
                BrandLoaderView(size: 56)
                    .frame(maxWidth: .infinity)
                    .padding(32)
            }
            if let error = model.error {
                HomeAPIError(message: error) {
                    Task { await model.load(id: id, language: language.apiLanguage) }
                }
            }
            if let question = model.question {
                HStack(spacing: 14) {
                    VStack(alignment: .leading, spacing: 6) {
                        if let category = question.category {
                            Text(category.title)
                                .font(AppFont.medium(size: 12))
                                .foregroundStyle(AppColor.primary)
                        }
                        Text(question.question)
                            .font(AppFont.bold(size: 19))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    FAQSymbol(name: question.category?.icon, size: 56)
                }
                .padding(16)
                .background(AppColor.surface, in: RoundedRectangle(cornerRadius: 18))

                if let answer = question.answer ?? question.shortAnswer, !answer.isEmpty {
                    Text(answer)
                        .font(AppFont.regular(size: 15))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(16)
                        .background(AppColor.surface, in: RoundedRectangle(cornerRadius: 16))
                }
                if !question.steps.isEmpty {
                    Text((question.category?.slug == "purchase" ? "faq.purchaseSteps" : "faq.steps").localized)
                        .font(AppFont.bold(size: 16))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 4)
                    ForEach(question.steps) { step in
                        HStack(alignment: .top, spacing: 12) {
                            FAQSymbol(name: step.icon, size: 42)
                            VStack(alignment: .leading, spacing: 6) {
                                HStack(spacing: 8) {
                                    Text(String(step.number))
                                        .font(AppFont.bold(size: 12))
                                        .foregroundStyle(.white)
                                        .frame(width: 24, height: 24)
                                        .background(AppColor.primary, in: Circle())
                                    Text(step.title)
                                        .font(AppFont.bold(size: 15))
                                }
                                Text(step.description)
                                    .font(AppFont.regular(size: 13))
                                    .foregroundStyle(AppColor.secondaryText)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(AppColor.surface, in: RoundedRectangle(cornerRadius: 16))
                    }
                }
                if let tip = question.tip, !tip.isEmpty {
                    Label(tip, systemImage: "checkmark")
                        .font(AppFont.medium(size: 13))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(16)
                        .background(Color.green.opacity(0.12), in: RoundedRectangle(cornerRadius: 16))
                }
            }
        }
        .task(id: "\(id):\(language.apiLanguage)") {
            await model.load(id: id, language: language.apiLanguage)
        }
    }
}

private struct FAQSymbol: View {
    let name: String?
    let size: CGFloat

    var body: some View {
        Image(systemName: symbol)
            .font(.system(size: size * 0.42, weight: .regular))
            .foregroundStyle(AppColor.primary)
            .frame(width: size, height: size)
            .background(AppColor.accentSurface, in: RoundedRectangle(cornerRadius: 14))
            .accessibilityHidden(true)
    }

    private var symbol: String {
        switch name {
        case "shopping-bag": return "bag"
        case "ticket": return "ticket"
        case "search": return "magnifyingglass"
        case "file-text": return "doc.text"
        case "credit-card": return "creditcard"
        case "wallet": return "wallet.pass"
        case "clock": return "clock"
        default: return "questionmark.circle"
        }
    }
}
