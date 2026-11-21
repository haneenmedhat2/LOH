import SwiftUI
import UIKit

struct PurchaseDetailOfferCard: View {
    let purchase: PurchaseDetail
    let status: PurchaseStatus?
    @State private var referenceCopied = false

    var body: some View {
        VStack(spacing: 0) {
            if status == .ready {
                HomePhoto(asset: purchase.coupon.image ?? "")
                    .frame(height: 160)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay {
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(AppColor.border, lineWidth: 1)
                    }
                VStack(alignment: .leading, spacing: 16) {
                    identity
                    purchaseInformation
                }
                .padding(16)
            } else {
                VStack(alignment: .leading, spacing: 16) {
                    HStack(alignment: .top, spacing: 12) {
                        if let image = purchase.coupon.image, !image.isEmpty {
                            HomePhoto(asset: image)
                                .frame(width: status == .used ? 80 : 100, height: status == .used ? 80 : 100)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay {
                                    RoundedRectangle(cornerRadius: 12)
                                        .strokeBorder(AppColor.border, lineWidth: 1)
                                }
                        }
                        VStack(alignment: .leading, spacing: 10) {
                            identity
                            if let address = purchase.store?.address, !address.isEmpty {
                                locationText(address)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    if purchase.order != nil {
                        separator
                        if status == .used {
                            usedReceipt
                        } else {
                            purchaseInformation
                        }
                    }
                }
                .padding(16)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var identity: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let name = purchase.store?.name, !name.isEmpty {
                Text(name)
                    .font(status == .ready ? AppFont.medium(size: 13) : AppFont.bold(size: 14))
                    .foregroundStyle(status == .ready ? AppColor.primary : AppColor.text)
            }
            Text(purchase.coupon.name)
                .font(AppFont.extraBold(size: 17))
                .foregroundStyle(AppColor.text)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var purchaseInformation: some View {
        VStack(spacing: 0) {
            if status == .ready, let address = purchase.store?.address, !address.isEmpty {
                informationRow("location") {
                    locationText(address)
                }
            }
            if let amount = purchase.order?.paidAmount {
                informationRow("checkoutAmountPaid") {
                    Text(purchasePrice(amount, currency: purchase.order?.currency))
                        .font(AppFont.bold(size: 16))
                        .foregroundStyle(AppColor.primary)
                }
            }
            if let reference = purchase.order?.number, !reference.isEmpty {
                informationRow("orderNumber") {
                    referenceButton(reference)
                }
            }
            if let date = purchase.purchasedAt, !date.isEmpty {
                informationRow("purchaseDate") {
                    Text(date)
                        .font(AppFont.regular(size: 12))
                }
            }
            if let method = purchase.order?.paymentMethodText ?? purchase.order?.paymentMethod, !method.isEmpty {
                informationRow("paymentMethod", separatorVisible: false) {
                    Text(method)
                        .font(AppFont.medium(size: 13))
                }
            }
        }
    }

    private func locationText(_ address: String) -> some View {
        Text(address)
            .font(AppFont.regular(size: 12))
            .foregroundStyle(AppColor.secondaryText)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var usedReceipt: some View {
        HStack(alignment: .top, spacing: 16) {
            if let reference = purchase.order?.number, !reference.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text(homeText("orderNumber"))
                        .font(AppFont.regular(size: 12))
                        .foregroundStyle(AppColor.secondaryText)
                    referenceButton(reference)
                }
            }
            Spacer(minLength: 0)
            if let amount = purchase.order?.paidAmount {
                VStack(alignment: .trailing, spacing: 6) {
                    Text(homeText("checkoutAmountPaid"))
                        .font(AppFont.regular(size: 12))
                        .foregroundStyle(AppColor.secondaryText)
                    Text(purchasePrice(amount, currency: purchase.order?.currency))
                        .font(AppFont.extraBold(size: 18))
                        .foregroundStyle(AppColor.primary)
                }
            }
        }
    }

    private func informationRow<Value: View>(
        _ title: String,
        separatorVisible: Bool = true,
        @ViewBuilder value: () -> Value
    ) -> some View {
        VStack(spacing: 0) {
            HStack(alignment: .firstTextBaseline, spacing: 16) {
                Text(homeText(title))
                    .font(AppFont.regular(size: 13))
                    .foregroundStyle(AppColor.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
                value()
                    .multilineTextAlignment(.trailing)
            }
            .padding(.vertical, 12)
            if separatorVisible {
                separator
            }
        }
    }

    private func referenceButton(_ reference: String) -> some View {
        Button {
            UIPasteboard.general.string = reference
            referenceCopied = true
        } label: {
            HStack(spacing: 6) {
                Image("lohPurchaseReferenceCopy")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 13, height: 13)
                Text(referenceCopied ? homeText("codeCopied") : reference)
                    .font(AppFont.bold(size: 13))
                    .foregroundStyle(AppColor.text)
            }
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(homeText("copyOrderNumber"))
        .accessibilityValue(referenceCopied ? homeText("codeCopied") : reference)
    }

    private var separator: some View {
        AppColor.border.opacity(0.55)
            .frame(height: 1)
    }
}
