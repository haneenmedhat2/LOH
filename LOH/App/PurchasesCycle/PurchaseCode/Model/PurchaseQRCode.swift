import CoreImage.CIFilterBuiltins
import Foundation

enum PurchaseQRCode {
    /// Encode the server's voucher verbatim. Missing/redacted or unavailable
    /// vouchers must never be replaced by the design's sample QR pattern.
    static func image(for purchase: PurchaseDetail, fallbackStatus: PurchaseStatus?) -> CGImage? {
        guard purchase.canShowCode(status: fallbackStatus), let code = purchase.code else { return nil }
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(code.utf8)
        filter.correctionLevel = "M"
        guard let output = filter.outputImage else { return nil }
        // Keep a four-module white quiet zone so scanners can find the QR edges.
        let extent = output.extent.insetBy(dx: -4, dy: -4)
        let background = CIImage(color: .white).cropped(to: extent)
        let bordered = output.composited(over: background).cropped(to: extent)
        let scaled = bordered.transformed(by: CGAffineTransform(scaleX: 8, y: 8))
        return CIContext().createCGImage(scaled, from: scaled.extent)
    }
}
