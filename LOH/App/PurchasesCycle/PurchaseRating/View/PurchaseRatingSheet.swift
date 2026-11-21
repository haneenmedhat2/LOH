import SwiftUI

struct PurchaseRatingSheet: View {
    let purchase: PurchaseDetail
    @ObservedObject var details: PurchaseDetailViewModel
    @StateObject private var model: PurchaseRatingViewModel
    @ObservedObject private var language = AppLanguageManager.shared
    @Environment(\.dismiss) private var dismiss
    @FocusState private var commentFocused: Bool
    let onSubmitted: () -> Void

    init(
        purchase: PurchaseDetail, initialRating: Int, details: PurchaseDetailViewModel,
        onSubmitted: @escaping () -> Void
    ) {
        self.purchase = purchase
        self.details = details
        self.onSubmitted = onSubmitted
        _model = StateObject(wrappedValue: PurchaseRatingViewModel(initialRating: initialRating))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                closeButton
                merchantSummary
                VStack(spacing: 8) {
                    PurchaseRatingStars(value: Double(model.value), size: 40, spacing: 4) {
                        model.value = $0
                        details.clearRatingError()
                    }
                    .disabled(details.isSubmittingRating)
                    Text(homeText(model.canSubmit ? "ratingLevel\(model.value)" : "chooseRating"))
                        .font(AppFont.medium(size: 13))
                        .foregroundStyle(AppColor.primary)
                }
                commentField
                PurchaseRatingTags(model: model)
                    .disabled(details.isSubmittingRating)
                if let error = details.ratingError {
                    Text(error)
                        .font(AppFont.regular(size: 13))
                        .foregroundStyle(AppColor.error)
                        .multilineTextAlignment(.center)
                }
                actions
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 16)
            .frame(maxWidth: 540)
            .frame(maxWidth: .infinity)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(AppColor.surface)
        .foregroundStyle(AppColor.text)
        .task(id: language.apiLanguage) {
            await model.loadTags(language: language.apiLanguage)
        }
        .logScreen("PurchaseRatingSheet")
    }

    private var closeButton: some View {
        HStack {
            Spacer(minLength: 0)
            Button {
                dismiss()
            } label: {
                Image("lohRatingClose")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 16, height: 16)
                    .frame(width: 32, height: 32)
                    .background(AppColor.disabledSurface, in: Circle())
                    .frame(width: 44, height: 44)
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .disabled(details.isSubmittingRating)
            .accessibilityLabel(homeText("close"))
        }
    }

    private var merchantSummary: some View {
        HStack(spacing: 12) {
            HomePhoto(asset: purchase.store?.image ?? "", contentMode: .fit)
                .frame(width: 40, height: 40)
                .clipShape(Circle())
                .overlay {
                    Circle()
                        .strokeBorder(AppColor.border.opacity(0.6), lineWidth: 1)
                }
            VStack(spacing: 4) {
                if let name = purchase.store?.name, !name.isEmpty {
                    Text(name)
                        .font(AppFont.bold(size: 14))
                }
                Text(purchase.coupon.name)
                    .font(AppFont.regular(size: 12))
                    .foregroundStyle(AppColor.secondaryText)
            }
            .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    private var commentField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(homeText("optionalComment"))
                .font(AppFont.medium(size: 13))
            VStack(spacing: 8) {
                TextField(homeText("commentPlaceholder"), text: $model.comment, axis: .vertical)
                    .font(AppFont.regular(size: 14))
                    .lineLimit(3...5)
                    .frame(minHeight: 60, alignment: .topLeading)
                    .focused($commentFocused)
                    .disabled(details.isSubmittingRating)
                    .accessibilityLabel(homeText("optionalComment"))
                Text("\(model.comment.count)/\(PurchaseRatingViewModel.commentLimit)")
                    .font(AppFont.regular(size: 11))
                    .foregroundStyle(AppColor.mutedText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .environment(\.layoutDirection, .leftToRight)
            }
            .padding(12)
            .background(AppColor.surface, in: RoundedRectangle(cornerRadius: 16))
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(AppColor.border, lineWidth: 1)
            }
        }
    }

    private var actions: some View {
        VStack(spacing: 12) {
            Button {
                commentFocused = false
                Task {
                    let saved = await details.submitRating(
                        value: model.value, comment: model.comment,
                        tagIDs: model.selectedTagIDs.sorted(), language: language.apiLanguage
                    )
                    if saved {
                        onSubmitted()
                    }
                }
            } label: {
                HStack(spacing: 8) {
                    if details.isSubmittingRating {
                        BrandLoaderView(size: 28)
                    }
                    Text(homeText("submitRating"))
                }
            }
            .buttonStyle(
                MainButtonStyle(
                    variant: .action, isLoading: details.isSubmittingRating,
                    height: 56, cornerRadius: 16, font: AppFont.bold(size: 16)
                )
            )
            .disabled(!model.canSubmit || details.isSubmittingRating || !details.canRate)
            Button {
                dismiss()
            } label: {
                Text(homeText("notNow"))
                    .font(AppFont.medium(size: 15))
                    .foregroundStyle(AppColor.primary)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(details.isSubmittingRating)
        }
    }
}
