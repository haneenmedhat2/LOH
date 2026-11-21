import Foundation

/// The details endpoint returns a code object; scalar codes remain supported
/// for compatibility with existing response fixtures.
struct PurchaseVoucherCode: Decodable, Hashable {
    let number: String?
    let qrURL: URL?
    let isActive: Bool?
    let statusText: String?

    var usableNumber: String? {
        guard let number else { return nil }
        let trimmed = number.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed.uppercased() != "[REDACTED]" else { return nil }
        return number
    }

    private enum CodingKeys: String, CodingKey {
        case number = "coupon_number"
        case qr
        case isActive = "is_active"
        case statusText = "status_text"
    }

    init(number: String) {
        self.number = number
        qrURL = nil
        isActive = nil
        statusText = nil
    }

    init(from decoder: Decoder) throws {
        let scalar = try decoder.singleValueContainer()
        if let number = try? scalar.decode(String.self) {
            self = PurchaseVoucherCode(number: number)
            return
        }
        if let number = try? scalar.decode(Int64.self) {
            self = PurchaseVoucherCode(number: String(number))
            return
        }
        let c = try decoder.container(keyedBy: CodingKeys.self)
        if let text = try? c.decode(String.self, forKey: .number) {
            number = text
        } else if let value = try? c.decode(Int64.self, forKey: .number) {
            number = String(value)
        } else {
            number = nil
        }
        if let raw = try c.decodeIfPresent(String.self, forKey: .qr),
            let url = URL(string: raw), ["https", "http"].contains(url.scheme?.lowercased() ?? ""),
            let host = url.host, !host.isEmpty
        {
            qrURL = url
        } else {
            qrURL = nil
        }
        isActive = c.flexibleBool(.isActive) ?? false
        statusText = try c.decodeIfPresent(String.self, forKey: .statusText)
    }
}
