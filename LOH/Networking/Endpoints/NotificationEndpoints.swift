import Foundation

struct NotificationEndpoints {
    private init() {}
}

extension NotificationEndpoints {
    static
    func list(filter: NotificationsFilter, page: Int, token: String) -> Endpoint<APIEnvelope<NotificationsListData>> {
        return Endpoint(
            path: "notifications",
            queries: [
                "filter": filter.rawValue,
                "page": page,
                "paginate": 20
            ],
            headerType: .authorized(token: token)
        )
    }
    static
    func count(token: String) -> Endpoint<APIEnvelope<NotificationCount>> {
        return Endpoint(
            path: "count-notifications",
            headerType: .authorized(token: token)
        )
    }
    static
    func markAllAsRead(token: String) -> Endpoint<APIEnvelope<APIEmpty>> {
        return Endpoint(
            method: .patch,
            path: "read-notifications",
            headerType: .authorized(token: token)
        )
    }
    static
    func markAsRead(id: String, token: String) -> Endpoint<APIEnvelope<APIEmpty>> {
        return Endpoint(
            method: .patch,
            path: "read-notification/\(id)",
            headerType: .authorized(token: token)
        )
    }
    static
    func delete(id: String, token: String) -> Endpoint<APIEnvelope<APIEmpty>> {
        return Endpoint(
            method: .delete,
            path: "delete-notification/\(id)",
            headerType: .authorized(token: token)
        )
    }
    static
    func deleteAll(token: String) -> Endpoint<APIEnvelope<APIEmpty>> {
        return Endpoint(
            method: .delete,
            path: "delete-notifications",
            headerType: .authorized(token: token)
        )
    }
    static
    func settings(token: String) -> Endpoint<APIEnvelope<AccountNotificationPreferences>> {
        return Endpoint(
            path: "notification-settings",
            headerType: .authorized(token: token)
        )
    }
    static
    func update(_ key: AccountNotificationPreferenceKey, value: Bool, token: String) -> Endpoint<APIEnvelope<APIEmpty>> {
        return Endpoint(
            method: .patch,
            path: "notification-settings",
            body: [key.rawValue: value ? "1" : "0"],
            headerType: .authorized(token: token)
        )
    }
    static
    func switchStatus(token: String) -> Endpoint<APIEnvelope<NotificationStatus>> {
        return Endpoint(
            method: .patch,
            path: "switch-notify",
            headerType: .authorized(token: token)
        )
    }
}
