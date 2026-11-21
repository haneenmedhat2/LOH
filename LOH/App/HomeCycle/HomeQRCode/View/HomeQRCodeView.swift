import SwiftUI
import CoreImage.CIFilterBuiltins

struct HomeQRCodeView: View {
    let receipt: HomeCheckoutReceipt
    var body: some View {
        AccountPage(title: homeText("usageCode"), headerHeight: 56) {
            CardContainer {
                HStack(spacing: 12) {
                    VStack(spacing: 2) {
                        if receipt.offer.merchant == "Nawa Café" {
                            Image("lohCheckoutMerchantMark")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 22, height: 22)
                            Text("NAWA")
                                .font(.system(size: 6, weight: .bold))
                                .tracking(1)
                            Text("CAFÉ")
                                .font(.system(size: 4))
                                .tracking(1)
                        } else {
                            Text(String(receipt.offer.merchant.prefix(2)))
                                .font(AppFont.bold(size: 18))
                        }
                    }
                    .foregroundStyle(Color(red: 92 / 255, green: 74 / 255, blue: 50 / 255))
                    .frame(width: 56, height: 56)
                    .background(
                        Color(red: 245 / 255, green: 240 / 255, blue: 232 / 255), in: RoundedRectangle(cornerRadius: 16)
                    )
                    VStack(alignment: .leading, spacing: 6) {
                        Text(homeText(receipt.offer.merchant))
                            .font(AppFont.bold(size: 15))
                        Text(homeText(receipt.offer.title))
                            .font(AppFont.regular(size: 13))
                        HStack(spacing: 4) {
                            HomeIcon.pin.view(12)
                            Text(homeText("district"))
                                .font(AppFont.regular(size: 11))
                                .foregroundStyle(AppColor.secondaryText)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            CardContainer(padding: 20) {
                VStack(spacing: 20) {
                    Text(homeText("showCodeToStaff"))
                        .font(AppFont.bold(size: 15))
                        .foregroundStyle(AppColor.success)
                    if let image = qrImage {
                        Image(uiImage: image)
                            .interpolation(.none)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 200, height: 200)
                            .padding(12)
                            .background(.white, in: RoundedRectangle(cornerRadius: 16))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(AppColor.border.opacity(0.5))
                            )
                            .accessibilityLabel(homeText("usageCode") + " " + (receipt.code ?? ""))
                    }
                    Text(receipt.code ?? "")
                        .font(AppFont.bold(size: 28))
                        .tracking(2)
                        .foregroundStyle(AppColor.success)
                        .lineLimit(1)
                        .minimumScaleFactor(0.65)
                        .environment(\.layoutDirection, .leftToRight)
                    if let code = receipt.code { CheckoutCopyButton(code: code) }
                    Text(homeText("scanCodeHint"))
                        .font(AppFont.regular(size: 12))
                        .foregroundStyle(AppColor.secondaryText)
                    Text(homeText(receipt.isPreview ? "demoCodeHint" : "checkoutCodeInPurchases"))
                        .font(AppFont.medium(size: 13))
                        .foregroundStyle(AppColor.success)
                }
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
            }
            HomeDirectionsButton(merchant: homeText(receipt.offer.merchant))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(AppColor.primary, lineWidth: 1.5))
            if receipt.isPreview { CheckoutPreviewNote() }
        }
    }
    private var qrImage: UIImage? {
        guard let payload = receipt.qrPayload else { return nil }
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(payload.utf8)
        filter.correctionLevel = "M"
        guard let output = filter.outputImage,
            let image = CIContext()
                .createCGImage(
                    output.transformed(by: CGAffineTransform(scaleX: 8, y: 8)),
                    from: output.extent.applying(CGAffineTransform(scaleX: 8, y: 8)))
        else {
            return nil
        }
        return UIImage(cgImage: image)
    }
}
