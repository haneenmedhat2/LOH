import Foundation

struct PurchaseEndpoints {
    private init() {}
}

extension PurchaseEndpoints {
    static
    func list(status: PurchaseStatus?, page: Int, token: String) -> Endpoint<APIEnvelope<PurchasePage>> {
        var query: APIParameters = ["page": page]
        if let status { query["status"] = status.rawValue }
        return Endpoint(
            path: "user-coupons",
            queries: query,
            headerType: .authorized(token: token)
        )
    }
    static
    func details(id: Int, token: String) -> Endpoint<APIEnvelope<PurchaseDetailData>> {
        return Endpoint(
            path: "user-coupon-details/\(id)",
            headerType: .authorized(token: token)
        )
    }
    static
    func ratingTags() -> Endpoint<APIEnvelope<[PurchaseRatingTag]>> {
        return Endpoint(
            path: "rating-tags"
        )
    }
    static
    func rateStore(id: Int, fields: [(String, String)], token: String) -> Endpoint<APIEnvelope<APIEmpty>> {
        let body = fields.reduce(into: APIParameters()) { parameters, field in
            parameters[field.0] = field.1
        }
        return Endpoint(
            method: .post,
            path: "rate-store/\(id)",
            body: body,
            headerType: .authorized(token: token)
        )
    }
}
