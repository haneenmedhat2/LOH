import Foundation

enum PurchaseStatus: String, CaseIterable, Identifiable {
    case ready, used, expired = "ended"
    var id: String { rawValue }
    var titleKey: String {
        switch self {
        case .ready: return "purchaseTabReady"
        case .used: return "purchaseTabUsed"
        case .expired: return "purchaseTabExpired"
        }
    }
}

enum PurchaseFilter: String, CaseIterable, Identifiable {
    case all, ready, used, ended
    var id: String { rawValue }
    var status: PurchaseStatus? { PurchaseStatus(rawValue: rawValue) }
    var titleKey: String { status?.titleKey ?? "all" }
}

/// A purchased voucher. Its ID is distinct from the catalog coupon and store IDs.
struct PurchaseCoupon: Decodable, Equatable {
    let id: Int
    let couponID: Int?
    let storeID: Int?
    let couponNumber: String?
    let qrURL: URL?
    let availableCount: Int?
    let name: String
    let merchant: String
    let storeImage: String?
    let image: String?
    let code: String?
    let description: String?
    let price: Double?
    let currency: String?
    let status: PurchaseStatus?
    let statusText: String?
    let rating: PurchaseDetail.Rating?
    let location: String
    let purchasedAt: String?
    let expiresAt: String?
    let usedAt: String?
    let reference: String?
    let printLink: URL?

    private enum CodingKeys: String, CodingKey {
        case id, name, image, code, description, price, currency, status, cities, coupon, rating, address, location, qr
        case couponID = "coupon_id", storeID = "store_id", couponNumber = "coupon_number"
        case availableCount = "available_count", isRated = "is_rated", storeAddress = "store_address"
        case storeImage = "store_image", statusText = "status_text", orderNumber = "order_num"
        case merchant = "store_name", purchasedAt = "purchased_at", expiresAt = "expires_at"
        case usedAt = "used_at", reference = "order_number", printLink = "print_link"
    }
    private struct City: Decodable { let name: String }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        // New purchase responses group offer, merchant, order, and rating data.
        // Keep the purchased voucher ID for navigation, never the nested offer ID.
        if c.contains(.coupon) {
            let detail = try PurchaseDetail(from: decoder)
            id = detail.id
            couponID = detail.coupon.id
            storeID = detail.store?.id
            couponNumber = detail.voucherCode?.usableNumber
            qrURL = detail.voucherCode?.qrURL
            availableCount = nil
            name = detail.coupon.name
            merchant = detail.store?.name ?? ""
            storeImage = detail.store?.image
            image = detail.coupon.image
            code = detail.code
            description = detail.coupon.description
            price = detail.order?.paidAmount
            currency = detail.order?.currency
            status = detail.status
            statusText = detail.statusText
            rating = detail.rating
            location = detail.store?.address ?? ""
            purchasedAt = detail.purchasedAt
            expiresAt = detail.expiresAt
            usedAt = detail.usedAt
            reference = detail.order?.number
            printLink = detail.printLink
            return
        }
        guard let id = c.flexibleInt(.id), id > 0 else { throw APIError.invalidResponse }
        self.id = id
        couponID = c.flexibleInt(.couponID)
        storeID = c.flexibleInt(.storeID)
        couponNumber = Self.text(c, .couponNumber)
        qrURL = Self.webURL(c, .qr)
        availableCount = c.flexibleInt(.availableCount)
        name = try c.decode(String.self, forKey: .name)
        merchant = try c.decodeIfPresent(String.self, forKey: .merchant) ?? ""
        storeImage = try c.decodeIfPresent(String.self, forKey: .storeImage)
        image = try c.decodeIfPresent(String.self, forKey: .image)
        code = Self.text(c, .code)?.trimmingCharacters(in: .whitespacesAndNewlines)
        description = try c.decodeIfPresent(String.self, forKey: .description)
        if let value = try? c.decode(Double.self, forKey: .price) {
            price = value
        } else {
            price = Self.text(c, .price).flatMap { Double($0.replacingOccurrences(of: ",", with: "")) }
        }
        currency = try c.decodeIfPresent(String.self, forKey: .currency)
        status = (try c.decodeIfPresent(String.self, forKey: .status)).flatMap(PurchaseStatus.init(rawValue:))
        statusText = try c.decodeIfPresent(String.self, forKey: .statusText)
        if let value = try? c.decode(Double.self, forKey: .rating) {
            // The list returns a numeric rating plus a separate is_rated flag.
            // A zero rating with is_rated=false must not appear as submitted.
            rating = PurchaseDetail.Rating(
                canRate: false, isRated: c.flexibleBool(.isRated) ?? false,
                rating: value, comment: nil, label: nil
            )
        } else {
            rating = try c.decodeIfPresent(PurchaseDetail.Rating.self, forKey: .rating)
        }
        location = try c.decodeIfPresent(String.self, forKey: .storeAddress)
            ?? c.decodeIfPresent(String.self, forKey: .address)
            ?? c.decodeIfPresent(String.self, forKey: .location)
            ?? c.decodeIfPresent([City].self, forKey: .cities)?.map(\.name).joined(separator: "، ") ?? ""
        purchasedAt = Self.text(c, .purchasedAt)
        expiresAt = Self.text(c, .expiresAt)
        usedAt = Self.text(c, .usedAt)
        reference = Self.text(c, .reference) ?? Self.text(c, .orderNumber)
        printLink = Self.webURL(c, .printLink)
    }

    private static func text(_ c: KeyedDecodingContainer<CodingKeys>, _ key: CodingKeys) -> String? {
        if let value = try? c.decode(String.self, forKey: key) { return value }
        return c.flexibleInt(key).map(String.init)
    }

    private static func webURL(_ c: KeyedDecodingContainer<CodingKeys>, _ key: CodingKeys) -> URL? {
        guard let raw = try? c.decode(String.self, forKey: key),
            let url = URL(string: raw), ["https", "http"].contains(url.scheme?.lowercased() ?? ""),
            let host = url.host, !host.isEmpty
        else { return nil }
        return url
    }

    func canShowCode(status fallback: PurchaseStatus?) -> Bool {
        let status = status ?? fallback
        return status != .used && status != .expired && code?.isEmpty == false && code?.uppercased() != "[REDACTED]"
    }

    /// The code is loaded from details after navigation; the list may omit it.
    func canOpenCode(status fallback: PurchaseStatus?) -> Bool {
        (status ?? fallback) == .ready
    }
}

/// Older collection responses repeated IDs. Keep every row while using the
/// purchased-voucher server ID (never this presentation ID) for details.
struct PurchaseListRow: Identifiable {
    let id: String
    let coupon: PurchaseCoupon
}

struct PurchasePage: Decodable {
    let coupons: [PurchaseCoupon]
    let pagination: PurchasePagination?
    let counts: PurchaseCounts?
}

struct PurchaseCounts: Decodable, Equatable {
    let all: Int
    let ready: Int
    let used: Int
    let ended: Int

    var totals: [PurchaseFilter: Int] {
        [.all: all, .ready: ready, .used: used, .ended: ended]
    }

    private enum CodingKeys: String, CodingKey {
        case all, ready, used, ended
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        guard let all = c.flexibleInt(.all), all >= 0,
            let ready = c.flexibleInt(.ready), ready >= 0,
            let used = c.flexibleInt(.used), used >= 0,
            let ended = c.flexibleInt(.ended), ended >= 0
        else { throw APIError.invalidResponse }
        self.all = all
        self.ready = ready
        self.used = used
        self.ended = ended
    }
}

struct PurchasePagination: Decodable {
    let totalItems: Int
    let totalPages: Int
    let currentPage: Int
    private enum CodingKeys: String, CodingKey {
        case totalItems = "total_items", totalPages = "total_pages", currentPage = "current_page"
    }
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        guard let total = c.flexibleInt(.totalItems), total >= 0,
            let pages = c.flexibleInt(.totalPages), pages >= 0,
            let page = c.flexibleInt(.currentPage), page > 0, page <= max(1, pages)
        else {
            throw APIError.invalidResponse
        }
        totalItems = total
        totalPages = pages
        currentPage = page
    }
}
