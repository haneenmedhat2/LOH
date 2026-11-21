import SwiftUI

struct PurchaseDetailView: View {
    @StateObject private var model: PurchaseDetailViewModel
    @ObservedObject private var language = AppLanguageManager.shared
    @Environment(\.scenePhase) private var scenePhase
    @State private var showsRating = false
    @State private var initialRating = 0
    @State private var pendingRatingSuccess = false
    @State private var showsRatingSuccess = false
    init(id: Int, status: PurchaseStatus?) {
        _model = StateObject(wrappedValue: PurchaseDetailViewModel(id: id, status: status))
    }

    var body: some View {
        AccountPage(
            title: homeText("offerDetails"),
            hidesTabBar: true,
            contentSpacing: model.status == .expired ? 24 : 16,
            contentTopPadding: 20
        ) {
            if model.loading {
                BrandLoaderView(size: 56)
                    .frame(maxWidth: .infinity)
                    .padding(32)
            }
            if let error = model.error {
                HomeAPIError(message: error, retry: reload)
            }
            if let purchase = model.purchase {
                PurchaseDetailHeader(purchase: purchase, status: model.status)
                PurchaseDetailOfferCard(purchase: purchase, status: model.status)

                if model.status == .ready {
                    if let usage = purchase.howToUse, !usage.steps.isEmpty {
                        PurchaseUsageInstructions(usage: usage)
                    }
                    if model.canShowCode {
                        codeNotice
                    } else {
                        unavailableCode(purchase)
                    }
                } else {
                    unavailableCode(purchase)
                    if model.status == .used, let rating = model.rating,
                        rating.isRated || model.canRate
                    {
                        PurchaseDetailRatingCard(rating: rating, onRate: openRating)
                    }
                }
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if model.canShowCode {
                showCodeButton
            }
        }
        .sheet(isPresented: $showsRating, onDismiss: ratingSheetDismissed) {
            if let purchase = model.purchase {
                PurchaseRatingSheet(
                    purchase: purchase, initialRating: initialRating, details: model
                ) {
                    pendingRatingSuccess = true
                    showsRating = false
                }
                .presentationDetents([.height(614), .large])
                .presentationDragIndicator(.visible)
                .presentationBackground(AppColor.surface)
                .presentationCornerRadius(28)
                .interactiveDismissDisabled(model.isSubmittingRating)
                .environment(\.layoutDirection, language.apiLanguage == "ar" ? .rightToLeft : .leftToRight)
                .environment(\.locale, Locale(identifier: language.apiLanguage))
            }
        }
        .fullScreenCover(isPresented: $showsRatingSuccess) {
            PurchaseRatingSuccessPopup {
                presentRatingSuccess(false)
            }
            .presentationBackground(.clear)
            .interactiveDismissDisabled()
            .environment(\.layoutDirection, language.apiLanguage == "ar" ? .rightToLeft : .leftToRight)
            .environment(\.locale, Locale(identifier: language.apiLanguage))
        }
        .task(id: PurchaseLoadContext(filter: .all, language: language.apiLanguage, token: UserDefaults.accessToken)) {
            await model.load(language: language.apiLanguage)
        }
        .onChange(of: scenePhase) { phase in
            if phase == .active && !showsRating && !showsRatingSuccess && !model.isSubmittingRating {
                reload()
            }
        }
        .onChange(of: UserDefaults.accessToken) { _ in
            pendingRatingSuccess = false
            showsRating = false
            presentRatingSuccess(false)
        }
        .logScreen("PurchaseDetailView")
    }

    private var codeNotice: some View {
        HStack(alignment: .top, spacing: 8) {
            Image("lohPurchaseDetailWarning")
                .resizable()
                .scaledToFit()
                .frame(width: 14, height: 14)
            Text(homeText("purchaseCodePrivacyHint"))
                .font(AppFont.regular(size: 12))
                .foregroundStyle(AppColor.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 4)
    }

    private func unavailableCode(_ purchase: PurchaseDetail) -> some View {
        PurchaseDetailCodeCard(
            code: purchase.code,
            status: model.status,
            statusText: model.codeStatusText,
            isInactive: model.codeIsInactive,
            retry: model.codeIsInactive ? nil : reload
        )
    }

    private var showCodeButton: some View {
        NavigationLink {
            PurchaseCodeView(id: model.id, status: model.status)
        } label: {
            HStack(spacing: 10) {
                Image("lohPurchaseShowCode")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                Text(homeText("purchaseShowCode"))
            }
        }
        .buttonStyle(
            MainButtonStyle(variant: .primary, height: 56, cornerRadius: 16, font: AppFont.bold(size: 17))
        )
        .frame(maxWidth: 568)
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(AppColor.surface)
        .overlay(alignment: .top) {
            AppColor.border.opacity(0.6)
                .frame(height: 1)
        }
    }

    private func reload() {
        Task {
            await model.load(language: language.apiLanguage)
        }
    }

    private func openRating(_ value: Int) {
        guard model.canRate else { return }
        model.clearRatingError()
        initialRating = value
        pendingRatingSuccess = false
        showsRating = true
    }

    private func ratingSheetDismissed() {
        guard pendingRatingSuccess else { return }
        pendingRatingSuccess = false
        if model.rating?.isRated == true {
            presentRatingSuccess(true)
        }
    }

    private func presentRatingSuccess(_ presented: Bool) {
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            showsRatingSuccess = presented
        }
    }
}
