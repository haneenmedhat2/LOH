import Foundation

enum PushNotificationType: String {
    case adminID = "admin_id", ownerNotify = "owner_notify", adminNotify = "admin_notify"
    case cartNotify = "cart_notify", couponPublished = "coupon_published"
    case couponReminder = "coupon_reminder", orderUpdate = "order_update"
    case complaintReply = "complaint_reply", complaintClosed = "complaint_closed"
    case supportTicketChat = "support_ticket_chat"
    case blockNotify = "block_notify", deleteNotify = "delete_notify"
    case newOrder = "new_order", settlementRequest = "settlement_request"
    // Notifications sent before the mobile payload contract was updated.
    case legacyAdmin = "admin_notification"
    case legacyComplaint = "admin_reply_complaint_notification"
    case legacySettlementAccepted = "admin_accept_settlement_notification"
    case legacySettlementRejected = "admin_reject_settlement_notification"
    case legacyBlock = "block_notification", legacyDelete = "delete_account_notification"
    case legacyPoints = "points_transaction_notification"
}

enum PushDestination: Equatable {
    case notifications, cart, settlements, blocked, deleted
    case offer(Int), purchasedOffer(Int), order(Int), complaint(Int)
    case supportRoom(Int, ticketID: Int?)
}

struct PushPayload: Equatable {
    let type: PushNotificationType
    let couponID: Int?
    let userCouponID: Int?
    let orderID: Int?
    let complaintID: Int?
    let roomID: Int?
    let supportTicketID: Int?
    let title: String?
    let body: String?

    init?(userInfo: [AnyHashable: Any]) {
        // APNs flattens custom data; also accept the documented envelope.
        let data = userInfo["data"] as? [String: Any]
        func value(_ key: String) -> Any? { data?[key] ?? userInfo[key] }
        guard let rawType = value("type") as? String,
              let type = PushNotificationType(rawValue: rawType) else { return nil }
        self.type = type
        couponID = Self.positiveID(value("coupon_id"))
        userCouponID = Self.positiveID(value("user_coupon_id"))
        orderID = Self.positiveID(value("order_id"))
        complaintID = Self.positiveID(value("complaint_id"))
        roomID = Self.positiveID(value("room_id"))
        supportTicketID = Self.positiveID(value("support_ticket_id"))
        let language = UserDefaults.standard.string(forKey: "selectedLanguage") == "ar" ? "ar" : "en"
        let alert = (userInfo["aps"] as? [String: Any])?["alert"] as? [String: Any]
        title = value("title_\(language)") as? String
            ?? value("title") as? String
            ?? alert?["title"] as? String
        body = value("body_\(language)") as? String
            ?? value("body") as? String
            ?? alert?["body"] as? String
    }

    init?(notification: NotificationModel) {
        guard let type = PushNotificationType(rawValue: notification.type) else { return nil }
        self.type = type
        couponID = Self.positiveID(notification.couponID)
        userCouponID = Self.positiveID(notification.userCouponID)
        orderID = Self.positiveID(notification.orderID)
        complaintID = Self.positiveID(notification.complaintID)
        roomID = Self.positiveID(notification.roomID)
        supportTicketID = Self.positiveID(notification.supportTicketID)
        title = notification.title
        body = notification.body
    }

    var destination: PushDestination {
        switch type {
        case .adminID, .ownerNotify, .couponPublished:
            return couponID.map(PushDestination.offer) ?? .notifications
        case .couponReminder:
            return userCouponID.map(PushDestination.purchasedOffer) ?? .notifications
        case .orderUpdate, .newOrder:
            return orderID.map(PushDestination.order) ?? .notifications
        case .complaintReply, .complaintClosed:
            return complaintID.map(PushDestination.complaint) ?? .notifications
        case .supportTicketChat:
            return roomID.map { .supportRoom($0, ticketID: supportTicketID) } ?? .notifications
        case .cartNotify: return .cart
        case .settlementRequest, .legacySettlementAccepted, .legacySettlementRejected: return .settlements
        case .blockNotify, .legacyBlock: return .blocked
        case .deleteNotify, .legacyDelete: return .deleted
        case .adminNotify, .legacyAdmin, .legacyComplaint, .legacyPoints: return .notifications
        }
    }

    private static func positiveID(_ value: Any?) -> Int? {
        let number: Int?
        if let string = value as? String { number = Int(string) }
        else if let int = value as? Int { number = int }
        else { number = nil }
        return number.flatMap { $0 > 0 ? $0 : nil }
    }
}

extension Notification.Name {
    static let pushDidReceiveForeground = Notification.Name("ctf.push.didReceiveForeground")
    static let pushDidTap = Notification.Name("ctf.push.didTap")
    static let notificationsShouldRefresh = Notification.Name("ctf.notifications.shouldRefresh")
}
