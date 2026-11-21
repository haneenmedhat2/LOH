import SwiftUI

struct PurchaseRatingTags: View {
    @ObservedObject var model: PurchaseRatingViewModel
    @ObservedObject private var language = AppLanguageManager.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if model.loadingTags {
                BrandLoaderView(size: 56)
                    .frame(maxWidth: .infinity)
            } else if let error = model.tagsError {
                Text(error)
                    .font(AppFont.regular(size: 12))
                    .foregroundStyle(AppColor.secondaryText)
                Button("api.retry".localized) {
                    Task {
                        await model.loadTags(language: language.apiLanguage)
                    }
                }
                .font(AppFont.medium(size: 13))
                .foregroundStyle(AppColor.primary)
            } else {
                ForEach(Array(stride(from: 0, to: model.tags.count, by: 2)), id: \.self) { start in
                    ViewThatFits(in: .horizontal) {
                        HStack(spacing: 10) {
                            row(start)
                        }
                        .fixedSize(horizontal: true, vertical: false)
                        VStack(alignment: .leading, spacing: 8) {
                            row(start)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func row(_ start: Int) -> some View {
        ForEach(Array(model.tags[start..<min(start + 2, model.tags.count)])) { tag in
            tagButton(tag)
        }
    }

    private func tagButton(_ tag: PurchaseRatingTag) -> some View {
        let selected = model.selectedTagIDs.contains(tag.id)
        return Button {
            model.toggleTag(tag.id)
        } label: {
            HStack(spacing: 6) {
                if let asset = icon(for: tag.id) {
                    Image(asset)
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .foregroundStyle(selected ? AppColor.primary : AppColor.mutedText)
                        .frame(width: 12, height: 12)
                }
                Text(tag.name)
                    .font(AppFont.medium(size: 12))
                    .foregroundStyle(selected ? AppColor.primary : AppColor.text)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(minHeight: 36)
            .background(selected ? AppColor.accentSurface : AppColor.surface, in: RoundedRectangle(cornerRadius: 12))
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(selected ? AppColor.primary : AppColor.border, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    private func icon(for id: Int) -> String? {
        switch id {
        case 1: return "lohRatingTagFast"
        case 2: return "lohRatingTagQuality"
        case 3: return "lohRatingTagAccurate"
        default: return nil
        }
    }
}
