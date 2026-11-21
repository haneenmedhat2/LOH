import Foundation

enum NotificationsFilter: String, CaseIterable {
    case all, offers, updates
}

struct NotificationsListData: Decodable {
    let data: [NotificationModel]
    let sections: [NotificationSection]
    let pagination: NotificationPagination?

    private enum CodingKeys: String, CodingKey { case notifications, data, sections, pagination }
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if container.contains(.notifications) {
            let nested = try container.decode(NotificationsListData.self, forKey: .notifications)
            data = nested.data; sections = nested.sections; pagination = nested.pagination
        } else {
            if container.contains(.sections) {
                sections = try container.decode([NotificationSection].self, forKey: .sections)
                data = sections.flatMap(\.notifications)
            } else {
                data = try container.decode([NotificationModel].self, forKey: .data)
                sections = []
            }
            pagination = try container.decodeIfPresent(NotificationPagination.self, forKey: .pagination)
        }
    }
}

struct NotificationSection: Decodable, Identifiable {
    let key: String
    let title: String
    let notifications: [NotificationModel]
    var id: String { key }
    private enum CodingKeys: String, CodingKey { case key, title, notifications, items, data }

    init(key: String, title: String, notifications: [NotificationModel]) {
        self.key = key
        self.title = title
        self.notifications = notifications
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        key = try container.decodeIfPresent(String.self, forKey: .key) ?? "all"
        title = try container.decodeIfPresent(String.self, forKey: .title) ?? ""
        if container.contains(.notifications) {
            notifications = try container.decode([NotificationModel].self, forKey: .notifications)
        } else if container.contains(.items) {
            notifications = try container.decode([NotificationModel].self, forKey: .items)
        } else {
            notifications = try container.decode([NotificationModel].self, forKey: .data)
        }
    }
}

struct NotificationPagination: Decodable {
    let currentPage: Int
    let totalPages: Int
    let totalItems: Int
    private enum CodingKeys: String, CodingKey {
        case currentPage = "current_page", totalPages = "total_pages", totalItems = "total_items"
    }
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        guard let page = container.flexibleInt(.currentPage), page > 0,
              let pages = container.flexibleInt(.totalPages), pages >= 0,
              let total = container.flexibleInt(.totalItems), total >= 0 else { throw APIError.invalidResponse }
        currentPage = page; totalPages = pages; totalItems = total
    }
}

struct NotificationModel: Decodable, Identifiable, Equatable {
    let id: String
    let type: String
    let category: String
    let categoryLabel: String
    let title: String
    let body: String
    let createdAt: String
    let time: String
    let image: String?
    var isRead: Bool
    let isClickable: Bool
    let couponID: Int?
    let userCouponID: Int?
    let orderID: Int?
    let complaintID: Int?
    let roomID: Int?
    let supportTicketID: Int?

    private enum CodingKeys: String, CodingKey {
        case id, key, type, category, categoryLabel = "category_label", title, body, time, image, isRead = "is_read"
        case createdAt = "created_at", isClickable = "is_clickable", couponID = "coupon_id"
        case userCouponID = "user_coupon_id", orderID = "order_id"
        case complaintID = "complaint_id", roomID = "room_id"
        case supportTicketID = "support_ticket_id", dataType = "data_type"
    }
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        guard !id.isEmpty else { throw APIError.invalidResponse }
        // "key" is a backend grouping value, never a navigation type.
        let apiType = try container.decodeIfPresent(String.self, forKey: .type) ?? ""
        let dataType = try container.decodeIfPresent(String.self, forKey: .dataType)
        type = apiType == "owner_notify" && dataType == "admin_id" ? "admin_id" : apiType
        category = try container.decodeIfPresent(String.self, forKey: .category) ?? ""
        categoryLabel = try container.decodeIfPresent(String.self, forKey: .categoryLabel) ?? ""
        title = try container.decodeIfPresent(String.self, forKey: .title) ?? ""
        body = try container.decodeIfPresent(String.self, forKey: .body) ?? ""
        createdAt = try container.decodeIfPresent(String.self, forKey: .createdAt) ?? ""
        time = try container.decodeIfPresent(String.self, forKey: .time) ?? createdAt
        image = try container.decodeIfPresent(String.self, forKey: .image)
        isRead = container.flexibleBool(.isRead) ?? true
        isClickable = container.flexibleBool(.isClickable) ?? false
        couponID = container.flexibleInt(.couponID)
        userCouponID = container.flexibleInt(.userCouponID)
        orderID = container.flexibleInt(.orderID)
        complaintID = container.flexibleInt(.complaintID)
        roomID = container.flexibleInt(.roomID)
        supportTicketID = container.flexibleInt(.supportTicketID)
    }

    var destinationCouponID: Int? {
        guard isClickable, let couponID, couponID > 0,
              let kind = PushNotificationType(rawValue: type),
              [.adminID, .ownerNotify, .couponPublished].contains(kind)
        else { return nil }
        return couponID
    }

    var destination: PushDestination? {
        guard isClickable else { return nil }
        return PushPayload(notification: self)?.destination
    }
}
