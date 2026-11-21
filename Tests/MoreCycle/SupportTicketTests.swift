import Foundation

@MainActor enum SupportTicketTests {
    static func fixture(_ name: String) throws -> String {
        try String(contentsOf: URL(fileURLWithPath: #filePath).deletingLastPathComponent()
            .appendingPathComponent("Fixtures/\(name).json"), encoding: .utf8)
    }
    static func run(client: APIClient) async throws {
        let types = try fixture("ticket-types"), list = try fixture("my-tickets")
        let created = try fixture("send-ticket"), detail = try fixture("ticket-detail")
        let detailRequest = try SupportTicketEndpoints.detail(id: 49, token: "test").asURLRequest()
        precondition(detailRequest.cachePolicy == .reloadIgnoringLocalCacheData && detailRequest.timeoutInterval == 20)
        let service = LOHSupportTicketService(client: client)
        var token: String? = "ticket-session"
        let account = TicketListViewModel(service: service, currentToken: { token })
        AccountMock.handler = { request in
            precondition(request.value(forHTTPHeaderField: "Authorization") == "Bearer ticket-session")
            precondition(request.value(forHTTPHeaderField: "lang") == "ar")
            precondition(request.url!.path == "/api/my-tickets" && request.httpMethod == "GET")
            precondition(request.url!.query == "status=all&page=1")
            return (200, list)
        }
        await account.reload(language: "ar")
        precondition(account.loaded && account.error == nil && account.total == 1 && !account.hasMore)
        precondition(account.tickets[0].id == 49 && account.tickets[0].code == "#LOH-2610290001")
        precondition(account.counts["in_progress"] == 0)
        account.filter.search = "LOH-261029"
        precondition(account.filteredTickets.count == 1)
        account.filter.status = "in_progress"
        AccountMock.handler = { request in
            precondition(request.url!.query == "status=in_progress&page=1")
            return (200, #"{"key":"success","data":{"tickets":[],"counts":{"all":1,"in_progress":0}}}"#)
        }
        await account.reload(language: "ar")
        precondition(account.loaded && account.tickets.isEmpty)
        account.filter.status = "all"
        AccountMock.handler = { request in
            let page = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)!.queryItems!.first { $0.name == "page" }!.value!
            let json = list.replacingOccurrences(of: "\"total_pages\": 1", with: "\"total_pages\": 2")
                .replacingOccurrences(of: "\"total_items\": 1", with: "\"total_items\": 2")
                .replacingOccurrences(of: "\"current_page\": 1", with: "\"current_page\": \(page)")
            return (200, page == "1" ? json : json.replacingOccurrences(of: "\"id\": 49", with: "\"id\": 50"))
        }
        await account.reload(language: "ar")
        precondition(account.hasMore && account.tickets.count == 1)
        await account.loadMore(language: "ar")
        precondition(!account.hasMore && account.tickets.map(\.id) == [49, 50])
        let form = NewTicketViewModel()
        AccountMock.handler = { request in
            precondition(request.url!.path == "/api/ticket-types" && request.httpMethod == "GET")
            return (200, types)
        }
        await form.loadTypes(using: account, language: "ar")
        precondition(form.types.first?.id == 1 && !form.canSubmit)
        form.form = NewTicketForm(category: "1", title: " title ", details: " new complation ")
        precondition(form.canSubmit)
        AccountMock.handler = { request in
            precondition(request.url!.path == "/api/send-ticket" && request.httpMethod == "POST")
            let body = AccountTests.body(request)
            precondition(body.contains("name=\"ticket_type_id\"\r\n\r\n1\r\n"))
            precondition(body.contains("name=\"title\"\r\n\r\ntitle\r\n"))
            precondition(body.contains("name=\"description\"\r\n\r\nnew complation\r\n"))
            precondition(!body.contains("order_id"))
            return (422, #"{"key":"fail","msg":"Rejected"}"#)
        }
        await form.submit(using: account, language: "ar")
        precondition(form.createdID == nil && form.error == "Rejected" && form.form.title == " title ")
        AccountMock.handler = { _ in (200, created) }
        await form.submit(using: account, language: "ar")
        precondition(form.createdID == 49 && form.createdTicket?.reference == "LOH-2610290001")
        let draft = SupportTicketSubmission(typeID: 1, orderID: 528, title: "title", description: "description")
        let request = try SupportTicketEndpoints.create(draft, token: "test")
        precondition(request.fields.contains { $0.0 == "order_id" && $0.1 == "528" })
        precondition(!SupportTicketSubmission(typeID: 0, orderID: nil, title: "a", description: "ab").isValid)
        precondition(!SupportTicketSubmission(typeID: 1, orderID: nil, title: String(repeating: "a", count: 192), description: "ab").isValid)
        precondition(!NewTicketForm(category: "1", title: "A", details: "x").valid)
        let screen = TicketDetailsViewModel()
        AccountMock.handler = { request in
            precondition(request.url!.path == "/api/my-tickets/49")
            return (200, detail)
        }
        await screen.load(id: 49, using: account, language: "ar")
        precondition(screen.ticket?.id == 49 && screen.ticket?.description == "new complation")
        precondition(screen.ticket?.status == "open")
        precondition(!screen.canReply, "ticket.can_user_reply controls replies even when top-level can_reply is true")
        let replyDetail = detail.replacingOccurrences(of: "\"can_reply\": true", with: "\"can_reply\": false")
            .replacingOccurrences(of: "\"can_user_reply\": false", with: "\"can_user_reply\": true")
        AccountMock.handler = { _ in (200, replyDetail) }
        await screen.load(id: 49, using: account, language: "ar")
        precondition(screen.canReply, "ticket.can_user_reply permits replies even when top-level can_reply is false")
        screen.replyText = " reply "
        AccountMock.handler = { request in
            precondition(request.url!.path == "/api/my-tickets/49/reply" && request.httpMethod == "POST")
            precondition(AccountTests.body(request).contains("name=\"replay\"\r\n\r\nreply\r\n"))
            return (422, #"{"key":"fail","msg":"Reply rejected"}"#)
        }
        await screen.send(id: 49, using: account, language: "ar")
        precondition(screen.replyText == " reply " && screen.sendError == "Reply rejected")
        var refreshes = 0
        AccountMock.handler = { request in
            if request.httpMethod == "POST" { return (200, #"{"key":"success","data":{}}"#) }
            refreshes += 1
            return (200, replyDetail)
        }
        await screen.send(id: 49, using: account, language: "ar")
        precondition(screen.replyText.isEmpty && screen.sendError == nil && refreshes == 1)
        AccountMock.handler = { _ in (200, detail) }
        await screen.load(id: 49, using: account, language: "ar")
        screen.replyText = "Forbidden reply"
        precondition(!screen.canSend)
        AccountMock.handler = { _ in preconditionFailure("Replies must not be sent when can_user_reply is false") }
        await screen.send(id: 49, using: account, language: "ar")
        let refreshedDetail = replyDetail.replacingOccurrences(of: "\"body\": \"new complation\"", with: "\"body\": \"Updated message\"")
        AccountMock.handler = { _ in (200, refreshedDetail) }
        await screen.load(id: 49, using: account, language: "ar")
        precondition(screen.canReply && screen.replies.first?.text == "Updated message", "Refresh must replace the conversation and reply permission")
        let orderDetail = detail.replacingOccurrences(of: "\"order_id\": null,\n      \"ticket_type_id\"", with: "\"order_id\": 988,\n      \"ticket_type_id\"")
            .replacingOccurrences(of: "\"order\": null", with: ##""order": {"id": 988, "order_code": "#LOH-2026988"}"##)
        let withOrder = try JSONDecoder().decode(APIEnvelope<SupportTicketDetail>.self, from: Data(orderDetail.utf8)).data!
        precondition(withOrder.ticket.orderID == 988 && withOrder.ticket.order?.label == "#LOH-2026988")
        let legacyDetail = detail.replacingOccurrences(of: ",\n    \"can_reply\": true", with: "")
        let legacy = try JSONDecoder().decode(APIEnvelope<SupportTicketDetail>.self, from: Data(legacyDetail.utf8)).data!
        precondition(!legacy.ticket.canUserReply)
        token = nil
        await account.reload(language: "ar")
        precondition(account.error != nil && !account.loaded)
        account.resetSession()
        precondition(account.tickets.isEmpty && account.counts.isEmpty && !account.loading)
        try await races(list: list, detail: detail, created: created)
        print("PASS: support ticket endpoint contracts, supplied responses, server IDs/types, status filters, validation, creation failures and read-only ticket details")
    }

    static func races(list: String, detail: String, created: String) async throws {
        let service = ControlledTicketService()
        let account = TicketListViewModel(service: service, currentToken: { "session" })
        let first = Task { await account.reload(language: "ar") }
        await service.waitForLists(1)
        account.filter.status = "closed"
        let second = Task { await account.reload(language: "en") }
        await service.waitForLists(2)
        let empty = try JSONDecoder().decode(SupportTicketPage.self, from: Data(#"{"tickets":[],"counts":{"closed":0}}"#.utf8))
        await service.resolveList(1, empty)
        await second.value
        let populated = try JSONDecoder().decode(APIEnvelope<SupportTicketPage>.self, from: Data(list.utf8)).data!
        await service.resolveList(0, populated)
        await first.value
        precondition(account.tickets.isEmpty && account.counts["closed"] == 0, "Old filter results must not overwrite the selected filter")
        let pending = Task { await account.reload(language: "ar") }
        await service.waitForLists(3)
        account.resetSession()
        await service.resolveList(2, populated)
        await pending.value
        precondition(account.tickets.isEmpty && !account.loaded, "Logout invalidates pending ticket responses")
        let form = NewTicketViewModel()
        await form.loadTypes(using: account, language: "en")
        form.form = NewTicketForm(category: "1", title: "A title", details: "An issue")
        let submission = Task { await form.submit(using: account, language: "en") }
        await service.waitForCreates(1)
        await form.submit(using: account, language: "en")
        let createCount = await service.createCount
        precondition(createCount == 1, "Double taps must not create duplicate tickets")
        account.resetSession()
        let ticket = try JSONDecoder().decode(APIEnvelope<AccountTicket>.self, from: Data(created.utf8)).data!
        await service.resolveCreate(ticket)
        await submission.value
        precondition(form.createdTicket == nil, "A creation response from a previous session must not show success")
    }
}

private actor ControlledTicketService: SupportTicketServicing {
    var lists: [CheckedContinuation<SupportTicketPage, Error>] = []
    var creates: [CheckedContinuation<AccountTicket, Error>] = []
    var createCount: Int { creates.count }
    func waitForCreates(_ count: Int) async { while creates.count < count { await Task.yield() } }
    func resolveCreate(_ ticket: AccountTicket) { creates[0].resume(returning: ticket) }
    func waitForLists(_ count: Int) async { while lists.count < count { await Task.yield() } }
    func resolveList(_ index: Int, _ page: SupportTicketPage) { lists[index].resume(returning: page) }
    func tickets(status: SupportTicketStatus, page: Int, token: String, language: String) async throws -> SupportTicketPage {
        try await withCheckedThrowingContinuation { lists.append($0) }
    }
    func types(token: String, language: String) async throws -> [SupportTicketType] { [.init(id: 1, name: "Issue")] }
    func detail(id: Int, page: Int, token: String, language: String) async throws -> SupportTicketDetail { throw APIError.invalidResponse }
    func create(_ submission: SupportTicketSubmission, token: String, language: String) async throws -> AccountTicket {
        try await withCheckedThrowingContinuation { creates.append($0) }
    }
}
