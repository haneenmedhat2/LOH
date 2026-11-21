import Foundation

enum APIError: Error { case invalidResponse }

extension KeyedDecodingContainer {
    func flexibleInt(_ key: Key) -> Int? {
        if let value = try? decode(Int.self, forKey: key) { return value }
        if let value = try? decode(String.self, forKey: key) { return Int(value) }
        return nil
    }
    func flexibleBool(_ key: Key) -> Bool? {
        if let value = try? decode(Bool.self, forKey: key) { return value }
        if let value = flexibleInt(key) { return value != 0 }
        return nil
    }
}

@main struct NotificationPayloadTests {
    static func main() throws {
        func push(_ fields: [String: String]) -> PushPayload {
            guard let payload = PushPayload(userInfo: fields) else { fatalError("Invalid push: \(fields)") }
            return payload
        }
        assert(push(["type": "admin_id", "coupon_id": "12", "key": "owner_notify"]).destination == .offer(12))
        assert(push(["type": "cart_notify", "key": "owner_notify"]).destination == .cart)
        assert(push(["type": "coupon_reminder", "user_coupon_id": "35", "coupon_id": "12"]).destination == .purchasedOffer(35))
        assert(push(["type": "order_update", "order_id": "25", "coupon_id": "12"]).destination == .order(25))
        assert(push(["type": "complaint_closed", "complaint_id": "9", "is_closed": "1"]).destination == .complaint(9))
        assert(push(["type": "support_ticket_chat", "room_id": "18", "support_ticket_id": "4"]).destination == .supportRoom(18, ticketID: 4))
        assert(push(["type": "coupon_published", "coupon_id": "0"]).destination == .notifications)
        assert(push(["type": "delete_notify"]).destination == .deleted)
        assert(push(["type": "block_notify"]).destination == .blocked)
        assert(PushPayload(userInfo: ["key": "owner_notify"]) == nil)
        assert(PushPayload(userInfo: ["data": ["type": "new_order", "order_id": "25"]])?.destination == .order(25))
        let localized = PushPayload(userInfo: [
            "type": "delete_notify", "body_en": "Removed",
            "aps": ["alert": ["body": "Fallback"]]
        ])
        assert(localized?.body == "Removed")

        let decoder = JSONDecoder()
        let api = """
        {"id":"uuid","type":"owner_notify","data_type":"admin_id","key":"owner_notify",
         "title":"Offer","body":"Details","is_read":false,"is_clickable":true,
         "coupon_id":12,"user_coupon_id":35,"order_id":25,"complaint_id":0}
        """
        let row = try decoder.decode(NotificationModel.self, from: Data(api.utf8))
        assert(row.type == "admin_id")
        assert(row.destination == .offer(12))
        assert(row.destinationCouponID == 12)
        let order = """
        {"id":"order","type":"order_update","key":"owner_notify",
         "is_clickable":true,"order_id":"25"}
        """
        let orderRow = try decoder.decode(NotificationModel.self, from: Data(order.utf8))
        assert(orderRow.destination == .order(25))
        print("Notification payload contract tests passed")
    }
}
