import Foundation

@MainActor
enum NotificationTests {
    static func page(_ ids: [String], current: Int = 1, pages: Int = 1) -> String {
        let items = ids.map { #"{"id":"\#($0)","key":"coupon_notify","title":"Offer","body":"Details","is_clickable":true,"coupon_id":"42","created_at":"Just now"}"# }.joined(separator: ",")
        return #"{"key":"success","data":{"data":[\#(items)],"pagination":{"total_items":\#(ids.count),"current_page":\#(current),"total_pages":\#(pages)}}}"#
    }
    static func decode(_ body: String) throws -> NotificationsListData {
        try JSONDecoder().decode(APIEnvelope<NotificationsListData>.self, from: Data(body.utf8)).data!
    }
    static func fixture(_ n: Int) throws -> String {
        let path = URL(fileURLWithPath: #filePath).deletingLastPathComponent().appendingPathComponent("Fixtures/notifications-\(n).json")
        return try String(contentsOf: path, encoding: .utf8)
    }

    static func run(client: APIClient, session: AuthSession) async throws {
        let service = LOHNotificationService(client: client)
        // Saved Postman examples, including the older nested envelope.
        for n in 0...3 {
            let list = try decode(fixture(n))
            precondition(list.pagination != nil)
            if n == 3 {
                precondition(list.data.count == 2 && list.data[0].type == "admin_notify")
                precondition(list.data[0].title == "إشعار إداري" && list.data[0].createdAt == "منذ دقيقتين")
                precondition(list.data.allSatisfy { $0.destinationCouponID == nil })
            }
            if n == 1 { precondition(list.pagination?.currentPage == 2 && list.data[0].type == "test") }
            if n == 2 { precondition(list.data.isEmpty) }
        }
        let clickable = try decode(page(["clickable"]))
        precondition(clickable.data[0].destinationCouponID == 42)
        for json in [#"{"key":"success","data":{}}"#,
                     #"{"key":"success","data":{"data":[{"title":"Missing ID"}]}}"#,
                     #"{"key":"success","data":{"data":[],"pagination":{"current_page":0}}}"#,
                     #"{"key":"success","data":{"sections":null}}"#,
                     #"{"key":"success","data":{"sections":[{"title":"Missing items"}]}}"#,
                     #"{"key":"success","data":{"sections":[{"items":[{"title":"Missing ID"}]}]}}}"#] {
            do { _ = try decode(json); preconditionFailure("Malformed inbox must fail, not become empty success") } catch {}
        }
        try await sectionedResponse(service: service, session: session)

        let sample = try fixture(3)
        var calls: [String] = []
        AccountMock.handler = { request in
            let path = request.url!.path
            calls.append(path)
            precondition(request.value(forHTTPHeaderField: "Authorization") == "Bearer test")
            precondition(request.value(forHTTPHeaderField: "lang") == "ar")
            switch path {
            case "/api/notifications":
                precondition(request.httpMethod == "GET" && request.url!.query == "filter=offers&page=2&paginate=20")
                return (200, sample)
            case "/api/count-notifications":
                precondition(request.httpMethod == "GET" && AccountTests.body(request).isEmpty)
                return (200, #"{"key":"success","data":{"count":"3"}}"#)
            case "/api/delete-notification/a-1", "/api/delete-notifications":
                precondition(request.httpMethod == "DELETE" && AccountTests.body(request).isEmpty)
            case "/api/switch-notify":
                precondition(request.httpMethod == "PATCH" && AccountTests.body(request).isEmpty)
                return (200, #"{"key":"success","data":{"notify":"0"}}"#)
            case "/api/notification-settings":
                if request.httpMethod == "GET" {
                    return (200, #"{"key":"success","data":{"new_offers":1,"order_updates":true,"offer_reminders":"0"}}"#)
                }
                precondition(request.httpMethod == "POST" && request.url!.query == "_method=patch")
                precondition(request.value(forHTTPHeaderField: "Content-Type")!.contains("multipart/form-data"))
                let body = AccountTests.body(request)
                precondition(AccountNotificationPreferenceKey.allCases.filter { body.contains("name=\"\($0.rawValue)\"\r\n\r\n0\r\n") }.count == 1)
            default: preconditionFailure("Unexpected notification request \(path)")
            }
            return (200, #"{"key":"success"}"#)
        }
        _ = try await service.notifications(filter: .offers, page: 2, token: "test", language: "ar")
        let count = try await service.count(token: "test", language: "ar")
        precondition(count == 3)
        try await service.delete(id: "a-1", token: "test", language: "ar")
        try await service.deleteAll(token: "test", language: "ar")
        let enabled = try await service.switchStatus(token: "test", language: "ar")
        precondition(!enabled)
        let preferences = try await service.settings(token: "test", language: "ar")
        precondition(preferences.newOffers && preferences.orderUpdates && !preferences.offerReminders)
        for key in AccountNotificationPreferenceKey.allCases {
            try await service.updateSetting(key, value: false, token: "test", language: "ar")
        }
        precondition(calls.count == 9)
        do {
            try await service.delete(id: "../invalid", token: "test", language: "ar")
            preconditionFailure("Invalid path must be rejected before networking")
        } catch {}
        precondition(calls.count == 9)
        for json in [#"{"key":"success","data":{}}"#, #"{"key":"success","data":{"count":-1}}"#] {
            AccountMock.handler = { _ in (200, json) }
            do { _ = try await service.count(token: "test", language: "ar"); preconditionFailure("Invalid count") } catch {}
        }
        try await paginationAndDeletion(service: service, session: session)
        await settings(client: client, session: session)
        try await races(session: session)

        let suite = "LOH.NotificationTests." + UUID().uuidString
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let guest = AuthSession(service: LOHAuthService(client: client), store: AccountTokenStore(), defaults: defaults)
        let model = NotificationsViewModel(service: service, session: guest)
        AccountMock.handler = { _ in preconditionFailure("Guest notifications must not make authenticated requests") }
        await model.refresh(language: "en")
        let deleted = await model.delete(id: nil, language: "en")
        precondition(model.requiresSignIn && model.notifications.isEmpty && model.count == nil && !deleted)
        print("PASS: all seven notification endpoints, Postman fixtures, filters/pagination, duplicate IDs, retries, count errors, confirmed mutations, preferences, guests and stale responses")
    }

    static func sectionedResponse(service: LOHNotificationService, session: AuthSession) async throws {
        // Exact successful empty response supplied from the live server.
        let path = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
            .appendingPathComponent("Fixtures/notifications-sections-empty.json")
        let empty = try String(contentsOf: path, encoding: .utf8)
        let decoded = try decode(empty)
        precondition(decoded.data.isEmpty && decoded.pagination?.totalItems == 0 && decoded.pagination?.currentPage == 1)

        // Synthetic compatibility cases for populated section wrappers.
        for key in ["notifications", "items", "data"] {
            let json = #"{"key":"success","data":{"sections":[{"title":"Today","\#(key)":[{"id":"a","title":"First"},{"id":"b","title":"Second"}]},{"title":"Earlier","\#(key)":[{"id":"c","title":"Third"}]}],"unread_count":2}}"#
            let sectioned = try decode(json)
            precondition(sectioned.data.map(\.id) == ["a", "b", "c"])
        }

        let model = NotificationsViewModel(service: service, session: session)
        var response = page(["old-notification"])
        AccountMock.handler = { request in
            switch request.url!.path {
            case "/api/notifications":
                precondition(request.httpMethod == "GET")
                precondition(request.url!.query == "filter=all&page=1&paginate=20")
                return (200, response)
            case "/api/count-notifications":
                return (200, #"{"key":"success","data":{"count":0}}"#)
            default: preconditionFailure("Unexpected empty-inbox request")
            }
        }
        await model.reload(filter: .all, language: "ar")
        precondition(model.notifications.count == 1)
        response = empty
        await model.refresh(language: "ar")
        precondition(model.hasLoaded && model.notifications.isEmpty && model.count == 0)
        precondition(!model.loading && !model.hasMore && model.error == nil && model.countError == nil)
        print("PASS: live empty sections response clears cached messages and shows successful empty state; grouped wrappers retain item order")
    }

    static func paginationAndDeletion(service: LOHNotificationService, session: AuthSession) async throws {
        let model = NotificationsViewModel(service: service, session: session)
        var failPage2 = true, failDelete = true, failCount = false
        var deleted = false, deletedAll = false, failReload = false
        var pagesRequested: [String] = []
        AccountMock.handler = { request in
            switch request.url!.path {
            case "/api/notifications":
                let query = request.url!.query!
                pagesRequested.append(query)
                if failReload { return (503, #"{"key":"fail","msg":"Inbox unavailable"}"#) }
                if deletedAll { return (200, page([])) }
                if deleted { return (200, page(["b", "c"])) }
                if query.contains("filter=updates") { return (200, page([])) }
                if query.contains("page=2") {
                    if failPage2 { return (503, #"{"key":"fail","msg":"Page unavailable"}"#) }
                    return (200, page(["b", "c", "c"], current: 2, pages: 2))
                }
                return (200, page(["a", "b", "a"], pages: 2))
            case "/api/count-notifications":
                if failCount { return (503, #"{"key":"fail","msg":"Count unavailable"}"#) }
                return (200, #"{"key":"success","data":{"count":\#(deletedAll ? 0 : deleted ? 2 : 3)}}"#)
            case "/api/delete-notification/a":
                if failDelete { return (422, #"{"key":"fail","msg":"Delete rejected"}"#) }
                deleted = true
                return (200, #"{"key":"success"}"#)
            case "/api/delete-notifications":
                deletedAll = true
                return (200, #"{"key":"success"}"#)
            default: preconditionFailure("Unexpected request")
            }
        }
        await model.refresh(language: "en")
        precondition(model.notifications.map(\.id) == ["a", "b"] && model.count == 3 && model.hasMore && model.hasLoaded)
        await model.loadMore()
        precondition(model.error == "Page unavailable" && model.notifications.count == 2 && model.hasMore)
        failPage2 = false
        await model.retry(language: "en")
        precondition(model.error == nil && model.notifications.map(\.id) == ["a", "b", "c"] && !model.hasMore)
        precondition(pagesRequested.suffix(2).allSatisfy { $0.contains("page=2") })
        let rejected = await model.delete(id: "a", language: "en")
        precondition(!rejected && model.notifications.count == 3 && model.mutationError == "Delete rejected")
        failDelete = false
        let removed = await model.delete(id: "a", language: "en")
        precondition(removed && model.notifications.map(\.id) == ["b", "c"] && model.count == 2 && model.mutationError == nil)
        precondition(pagesRequested.last!.contains("page=1"))
        failCount = true
        await model.refreshCount(language: "en")
        precondition(model.count == 2 && model.countError == "Count unavailable")
        failCount = false
        await model.refreshCount(language: "en")
        precondition(model.countError == nil)
        failReload = true
        await model.refresh(language: "en")
        precondition(model.notifications.map(\.id) == ["b", "c"] && model.error == "Inbox unavailable")
        await model.reload(filter: .offers, language: "en")
        precondition(model.filter == .offers && model.notifications.isEmpty && !model.hasLoaded && model.error != nil)
        failReload = false
        await model.retry(language: "en")
        precondition(model.hasLoaded && model.notifications.count == 2 && model.error == nil)
        let removedAll = await model.delete(id: nil, language: "en")
        precondition(removedAll && model.notifications.isEmpty && model.count == 0 && !model.hasMore)
        model.resetSession()
        precondition(!model.hasLoaded && model.count == nil && model.filter == .all)
    }

    static func settings(client: APIClient, session: AuthSession) async {
        let account = MoreAccountStore(service: LOHAccountService(client: client), session: session)
        let model = account.notifications
        var reject = false
        AccountMock.handler = { request in
            switch request.url!.path {
            case "/api/profile": return (200, #"{"key":"success","data":{"id":1,"is_notify":true}}"#)
            case "/api/notification-settings":
                if request.httpMethod == "GET" { return (200, #"{"key":"success","data":{"new_offers":true,"order_updates":false,"offer_reminders":true}}"#) }
                if reject { return (422, #"{"key":"fail","msg":"Preference rejected"}"#) }
                return (200, #"{"key":"success"}"#)
            case "/api/switch-notify":
                // Server state wins even when it differs from the requested toggle.
                return (200, #"{"key":"success","data":{"notify":true}}"#)
            default: preconditionFailure("Unexpected setting request")
            }
        }
        await model.loadNotifications()
        precondition(model.loaded && model.notifications && model.offerNotifications && !model.orderNotifications && model.reminderNotifications)
        await model.setEnabled(false)
        precondition(model.notifications)
        await model.setNotification(.orderUpdates, value: true)
        precondition(model.orderNotifications)
        reject = true
        await model.setNotification(.newOffers, value: false)
        precondition(model.offerNotifications && account.requests.error == "Preference rejected")
        account.resetSession()
        precondition(!model.loaded)
        AccountMock.handler = { _ in preconditionFailure("Unloaded settings cannot be changed") }
        await model.setEnabled(false)
        await model.setNotification(.offerReminders, value: false)
    }

    static func races(session: AuthSession) async throws {
        let service = DeferredNotifications()
        let model = NotificationsViewModel(service: service, session: session)
        let all = Task { await model.reload(filter: .all, language: "en") }
        while service.pending.count < 1 { await Task.yield() }
        let offers = Task { await model.reload(filter: .offers, language: "ar") }
        while service.pending.count < 2 { await Task.yield() }
        service.pending[1].resume(returning: try decode(page(["new-offer"])))
        await offers.value
        service.pending[0].resume(returning: try decode(page(["stale-all"])))
        await all.value
        precondition(model.filter == .offers && model.notifications.map(\.id) == ["new-offer"])
        let stale = Task { await model.refresh(language: "ar") }
        while service.pending.count < 3 { await Task.yield() }
        model.resetSession()
        service.pending[2].resume(returning: try decode(page(["old-session"])))
        await stale.value
        precondition(model.notifications.isEmpty && !model.hasLoaded && model.count == nil && !model.loading)
        let cancelled = Task { await model.reload(filter: .all, language: "en") }
        while service.pending.count < 4 { await Task.yield() }
        cancelled.cancel()
        service.pending[3].resume(returning: try decode(page(["cancelled"])))
        await cancelled.value
        precondition(model.notifications.isEmpty && model.error == nil && !model.loading)
    }
}

@MainActor
private final class DeferredNotifications: NotificationServicing {
    var pending: [CheckedContinuation<NotificationsListData, Error>] = []
    func notifications(filter: NotificationsFilter, page: Int, token: String, language: String) async throws -> NotificationsListData {
        try await withCheckedThrowingContinuation { pending.append($0) }
    }
    func count(token: String, language: String) async throws -> Int { 7 }
    func delete(id: String, token: String, language: String) async throws {}
    func deleteAll(token: String, language: String) async throws {}
}
