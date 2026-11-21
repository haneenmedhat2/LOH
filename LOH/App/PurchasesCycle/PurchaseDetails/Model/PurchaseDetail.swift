import Foundation

/// The purchased voucher ID is separate from both the coupon and order IDs.
struct PurchaseDetail: Decodable, Hashable {
    let id: Int
    let coupon: Offer
    let store: Store?
    let order: Order?
    let header: Header?
    let howToUse: UsageInstructions?
    let rating: Rating?
    let status: PurchaseStatus?
    let statusText: String?
    let voucherCode: PurchaseVoucherCode?
    let finishUsageAt: String?
    let finishUsageAtText: String?
    let usedAt: String?
    let printLink: URL?

    var expiresAt: String? { finishUsageAtText ?? finishUsageAt }
    var purchasedAt: String? { order?.purchasedAtText ?? order?.purchasedAt }
    var code: String? { voucherCode?.usableNumber }

    /// The response provides an address, not branch coordinates. Open a Maps
    /// search using that actual address and merchant name without inventing a pin.
    var storeSearchURL: URL? {
        guard let store, let address = store.address?.trimmingCharacters(in: .whitespacesAndNewlines),
            !address.isEmpty
        else { return nil }
        var components = URLComponents(string: "https://maps.apple.com/")
        components?.queryItems = [
            URLQueryItem(name: "q", value: [store.name, address].filter { !$0.isEmpty }.joined(separator: ", "))
        ]
        return components?.url
    }

    private enum CodingKeys: String, CodingKey {
        case id, coupon, store, order, header, rating, status, code
        case howToUse = "how_to_use", statusText = "status_text"
        case finishUsageAt = "finish_usage_at", finishUsageAtText = "finish_usage_at_text"
        case usedAt = "used_at"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        guard let id = c.flexibleInt(.id), id > 0 else { throw APIError.invalidResponse }
        self.id = id
        coupon = try c.decode(Offer.self, forKey: .coupon)
        store = try c.decodeIfPresent(Store.self, forKey: .store)
        order = try c.decodeIfPresent(Order.self, forKey: .order)
        header = try c.decodeIfPresent(Header.self, forKey: .header)
        howToUse = try c.decodeIfPresent(UsageInstructions.self, forKey: .howToUse)
        rating = try c.decodeIfPresent(Rating.self, forKey: .rating)
        status = (try c.decodeIfPresent(String.self, forKey: .status)).flatMap(PurchaseStatus.init(rawValue:))
        statusText = try c.decodeIfPresent(String.self, forKey: .statusText)
        voucherCode = try c.decodeIfPresent(PurchaseVoucherCode.self, forKey: .code)
        finishUsageAt = try c.decodeIfPresent(String.self, forKey: .finishUsageAt)
        finishUsageAtText = try c.decodeIfPresent(String.self, forKey: .finishUsageAtText)
        usedAt = try c.decodeIfPresent(String.self, forKey: .usedAt)
        printLink = nil
    }

    /// Compatibility with older direct/list detail responses from the collection.
    init(legacy: PurchaseCoupon) {
        id = legacy.id
        coupon = Offer(id: legacy.couponID, name: legacy.name, image: legacy.image, description: legacy.description)
        store = Store(id: legacy.storeID, name: legacy.merchant, image: legacy.storeImage, address: legacy.location)
        order = Order(
            id: nil, number: legacy.reference, paidAmount: legacy.price, currency: legacy.currency,
            paymentMethod: nil, paymentMethodText: nil, purchasedAt: legacy.purchasedAt, purchasedAtText: nil
        )
        header = nil
        howToUse = nil
        rating = legacy.rating
        status = legacy.status
        statusText = legacy.statusText
        voucherCode = legacy.code.map(PurchaseVoucherCode.init(number:))
        finishUsageAt = legacy.expiresAt
        finishUsageAtText = nil
        usedAt = legacy.usedAt
        printLink = legacy.printLink
    }

    func canShowCode(status fallback: PurchaseStatus?) -> Bool {
        let status = status ?? fallback
        guard status == .ready, let voucherCode, voucherCode.isActive != false else { return false }
        return voucherCode.usableNumber != nil || voucherCode.qrURL != nil
    }

    struct Offer: Decodable, Hashable {
        let id: Int?
        let name: String
        let image: String?
        let description: String?
    }

    struct Store: Decodable, Hashable {
        let id: Int?
        let name: String
        let image: String?
        let address: String?
    }

    struct Order: Decodable, Hashable {
        let id: Int?
        let number: String?
        let paidAmount: Double?
        let currency: String?
        let paymentMethod: String?
        let paymentMethodText: String?
        let purchasedAt: String?
        let purchasedAtText: String?
        enum CodingKeys: String, CodingKey {
            case id, currency
            case number = "order_num", paidAmount = "paid_amount"
            case paymentMethod = "payment_method", paymentMethodText = "payment_method_text"
            case purchasedAt = "purchased_at", purchasedAtText = "purchased_at_text"
        }
    }

    struct Header: Decodable, Hashable {
        let title: String?
        let description: String?
        let dateText: String?
        enum CodingKeys: String, CodingKey {
            case title, description
            case dateText = "date_text"
        }
    }

    struct UsageInstructions: Decodable, Hashable {
        let title: String
        let steps: [String]
    }

    struct Rating: Decodable, Hashable {
        let canRate: Bool
        let isRated: Bool
        let rating: Double?
        let comment: String?
        let label: String?
        var displayValue: Double? {
            guard isRated, let rating, rating.isFinite, (1...5).contains(rating) else { return nil }
            return rating
        }
        enum CodingKeys: String, CodingKey {
            case rating, comment
            case canRate = "can_rate", isRated = "is_rated", label = "rating_label"
        }
    }
}
