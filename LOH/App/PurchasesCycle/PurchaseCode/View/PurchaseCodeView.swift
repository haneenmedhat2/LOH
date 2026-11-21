import SwiftUI

struct PurchaseCodeView: View {
    // Both voucher screens use the same authenticated details loader and rules.
    @StateObject private var model: PurchaseDetailViewModel
    @ObservedObject private var language = AppLanguageManager.shared
    @Environment(\.scenePhase) private var scenePhase
    @State private var qrImage: CGImage?
    @State private var renderedCode: String?

    init(id: Int, status: PurchaseStatus?) {
        _model = StateObject(wrappedValue: PurchaseDetailViewModel(id: id, status: status))
    }

    var body: some View {
        AccountPage(title: homeText("usageCode"), contentSpacing: 12) {
            if model.loading {
                BrandLoaderView(size: 56)
                    .frame(maxWidth: .infinity)
                    .padding(32)
            }
            if let error = model.error {
                HomeAPIError(message: error, retry: reload)
            }
            if let purchase = model.purchase {
                merchantSummary(purchase)
                codeCard(purchase)
                    .task(id: purchase.voucherCode) {
                        qrImage = PurchaseQRCode.image(for: purchase, fallbackStatus: model.fallbackStatus)
                        renderedCode = purchase.code
                    }
                if let url = purchase.storeSearchURL {
                    Link(destination: url) {
                        HStack(spacing: 8) {
                            HomeIcon.directions.view(18)
                            Text(homeText("purchaseStoreDirections"))
                        }
                    }
                    .buttonStyle(
                        MainButtonStyle(variant: .outlined, height: 58, cornerRadius: 16, font: AppFont.bold(size: 15))
                    )
                }
            }
        }
        .task(id: PurchaseLoadContext(filter: .all, language: language.apiLanguage, token: UserDefaults.accessToken)) {
            await model.load(language: language.apiLanguage)
        }
        .onChange(of: scenePhase) { phase in
            if phase == .active {
                reload()
            }
        }
        .logScreen("PurchaseCodeView")
    }

    private func merchantSummary(_ purchase: PurchaseDetail) -> some View {
        CardContainer(padding: 16, cornerRadius: 16) {
            HStack(spacing: 12) {
                HomePhoto(asset: purchase.store?.image ?? "", contentMode: .fit)
                    .frame(width: 56, height: 56)
                    .background(AppColor.canvas)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay {
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(AppColor.border.opacity(0.5), lineWidth: 0.5)
                    }
                VStack(alignment: .leading, spacing: 6) {
                    if let merchant = purchase.store?.name, !merchant.isEmpty {
                        Text(merchant)
                            .font(AppFont.bold(size: 16))
                    }
                    Text(purchase.coupon.name)
                        .font(AppFont.regular(size: 14))
                    if let address = purchase.store?.address, !address.isEmpty {
                        PurchaseLocationLabel(address: address)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private func codeCard(_ purchase: PurchaseDetail) -> some View {
        CardContainer(padding: 20, cornerRadius: 16) {
            VStack(spacing: 20) {
                if model.canShowCode {
                    Text(homeText("showCodeToStaff"))
                        .font(AppFont.bold(size: 15))
                        .foregroundStyle(AppColor.success)
                    PurchaseQRImageView(
                        url: purchase.voucherCode?.qrURL,
                        fallback: renderedCode == purchase.code ? qrImage : nil
                    )
                    if let code = purchase.code {
                        Text(code)
                            .font(AppFont.bold(size: 28))
                            .tracking(3)
                            .foregroundStyle(AppColor.success)
                            .fixedSize(horizontal: false, vertical: true)
                            .textSelection(.enabled)
                            .environment(\.layoutDirection, .leftToRight)
                        CheckoutCopyButton(code: code)
                    }
                    Text(homeText("scanCodeHint"))
                        .font(AppFont.regular(size: 12))
                        .foregroundStyle(AppColor.secondaryText)
                    if model.status == .ready {
                        HStack(spacing: 8) {
                            Text(model.codeStatusText ?? homeText("purchaseCodeReady"))
                                .font(AppFont.medium(size: 13))
                            Image("lohPurchaseCodeReady")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 16, height: 16)
                        }
                        .foregroundStyle(AppColor.success)
                    }
                } else {
                    if let status = model.status, status != .ready || !model.codeIsInactive {
                        PurchaseStatusBadge(status: status, title: purchase.statusText)
                    }
                    Text(
                        model.codeStatusText
                            ?? homeText(model.codeIsInactive ? "codeUnavailable" : "purchaseCodeMissing")
                    )
                    .font(AppFont.regular(size: 14))
                    .foregroundStyle(AppColor.secondaryText)
                    if !model.codeIsInactive {
                        Button("api.retry".localized, action: reload)
                            .font(AppFont.bold(size: 14))
                            .foregroundStyle(AppColor.primary)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .multilineTextAlignment(.center)
        }
    }

    private func reload() {
        Task {
            await model.load(language: language.apiLanguage)
        }
    }
}
