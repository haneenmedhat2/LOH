import Foundation

struct PurchaseDetailData: Decodable {
    let purchases: [PurchaseDetail]
    private enum CodingKeys: String, CodingKey { case id, coupon, coupons }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        if c.contains(.id) && c.contains(.coupon) {
            purchases = [try PurchaseDetail(from: decoder)]
        } else if c.contains(.id) {
            purchases = [PurchaseDetail(legacy: try PurchaseCoupon(from: decoder))]
        } else if c.contains(.coupon) {
            purchases = [PurchaseDetail(legacy: try c.decode(PurchaseCoupon.self, forKey: .coupon))]
        } else {
            purchases = try c.decode([PurchaseCoupon].self, forKey: .coupons).map(PurchaseDetail.init(legacy:))
        }
    }
}
