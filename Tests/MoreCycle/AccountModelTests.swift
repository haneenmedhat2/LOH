import Foundation

final class UIImage { func jpegData(compressionQuality: Double) -> Data? { Data([1, 2, 3]) } }
enum AuthPreviewSession { static var user: User? }
extension UserDefaults { static var user: User?; static var isLogin = false }
enum AppLanguageManager { static func currentLanguage() -> String { "en" } }
extension String { var localized: String { self } }

final class AccountMock: URLProtocol {
    static var handler: ((URLRequest) throws -> (Int, String))!
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        do {
            let (status, body) = try Self.handler(request)
            client?.urlProtocol(self, didReceive: HTTPURLResponse(url: request.url!, statusCode: status, httpVersion: nil, headerFields: nil)!, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: Data(body.utf8)); client?.urlProtocolDidFinishLoading(self)
        } catch { client?.urlProtocol(self, didFailWithError: error) }
    }
    override func stopLoading() {}
}

final class AccountTokenStore: AuthTokenStoring {
    var token: String?
    func read() -> String? { token }
    func write(_ token: String) throws { self.token = token }
    func delete() { token = nil }
}

@main struct AccountTests {
    @MainActor static func main() async throws {
        let log = APILogger.json(["Authorization": "Bearer secret", "data": [
            "name": "Visible profile", "token": "private-token", "password": "private-password",
            "cards": [["card_number": "private-card", "cvv": "private-cvv"]]
        ]])
        precondition(log.contains("Visible profile") && !log.contains("[REDACTED]"))
        for secret in ["Bearer secret", "private-token", "private-password", "private-card", "private-cvv"] {
            precondition(log.contains(secret))
        }
        let config = URLSessionConfiguration.ephemeral; config.protocolClasses = [AccountMock.self]
        let client = APIClient(baseURL: URL(string: "https://example.invalid/api/")!, session: URLSession(configuration: config))
        let service = LOHAccountService(client: client)
        let upload = APIUpload(name: "image", filename: "profile.jpg", mimeType: "image/jpeg", data: Data("PHOTO".utf8))
        let request = try client.urlRequest(
            AccountEndpoints.updateProfile(fields: [("name", "Name")], files: [upload], token: "test"),
            language: "ar")
        let multipart = String(decoding: request.httpBody!, as: UTF8.self)
        precondition(multipart.contains("filename=\"profile.jpg\"") && multipart.contains("image/jpeg") && multipart.contains("PHOTO"))
        let cardJSON = #"{"id":"42","last_four":"4242","brand":"visa","expiry":"12/30","is_default":1,"holder_name":"Daily"}"#
        AccountMock.handler = { request in
            precondition(request.value(forHTTPHeaderField: "Authorization") == "Bearer test")
            precondition(request.value(forHTTPHeaderField: "lang") == "en")
            return (200, "{\"key\":\"success\",\"data\":[\(cardJSON)]}")
        }
        let list: AccountCardList = try await service.fetch(PaymentEndpoints.list(token: "test"), language: "en")
        precondition(list.cards[0].id == 42 && list.cards[0].lastFour == "4242" && list.cards[0].isDefault)
        let masked = try JSONDecoder().decode(AccountCard.self, from: Data(#"{"id":7,"card_number":"4242424242424242","is_default":false}"#.utf8))
        precondition(masked.lastFour == "4242")
        do {
            _ = try JSONDecoder().decode(AccountCard.self, from: Data(#"{"id":7,"is_default":false}"#.utf8))
            preconditionFailure("Missing card identity must not produce a fake card")
        } catch {}
        AccountMock.handler = { request in
            precondition(request.url!.path == "/api/payment-cards/42/rename" && request.url!.query == "_method=patch")
            precondition(request.httpMethod == "POST")
            precondition(body(request).contains("name=\"holder_name\"\r\n\r\nTravel\r\n"))
            return (200, #"{"key":"success"}"#)
        }
        try await service.perform(PaymentEndpoints.rename(id: 42, name: "Travel", token: "test"), language: "en")
        AccountMock.handler = { request in
            precondition(request.httpMethod == "PATCH" && request.url!.query == "lang=ar")
            return (200, #"{"key":"success"}"#)
        }
        try await service.changeLanguage("ar", token: "test")
        AccountMock.handler = { _ in (422, #"{"key":"fail","msg":"Rejected"}"#) }
        do {
            try await service.perform(AccountEndpoints.join(fields: [], token: "test"), language: "en")
            preconditionFailure("Server rejection must not become success")
        } catch { precondition(error.localizedDescription == "Rejected") }
        let prefs = try JSONDecoder().decode(AccountNotificationPreferences.self, from: Data(#"{"new_offers":"1","order_updates":false,"offer_reminders":0}"#.utf8))
        precondition(prefs.newOffers && !prefs.orderUpdates && !prefs.offerReminders)
        let suite = "LOH.AccountTests." + UUID().uuidString
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = AccountTokenStore()
        let session = AuthSession(service: LOHAuthService(client: client), store: store, defaults: defaults)
        let account = MoreAccountStore(service: service, session: session)
        let model = account.profile
        let payments = account.payments
        let tickets = account.tickets
        let requests = account.requests
        let saved = await payments.addCard(name: "Test", number: "4242424242424242", expiry: "12/30", cvv: "123", isDefault: true)
        precondition(!saved && payments.cards.isEmpty && !requests.busy)
        let auth = try JSONDecoder().decode(APIEnvelope<APIUser>.self, from: Data(#"{"key":"success","data":{"id":1,"token":"test","name":"Account","image":"https://example.invalid/avatar.jpg"}}"#.utf8))
        try session.accept(auth)
        model.loadSession()
        precondition(model.profile.name == "Account" && model.profile.imageURL == "https://example.invalid/avatar.jpg")
        let cachedRevision = model.profileImageRevision
        var profileRequests: [String] = []
        AccountMock.handler = { request in
            profileRequests.append(request.url!.path)
            switch request.url!.path {
            case "/api/profile":
                precondition(request.httpMethod == "GET")
                return (200, #"{"key":"success","data":{"id":1,"name":"Loaded profile","birth_date":"15 مايو 2000","email":"user@example.com","phone":"551234567","image":"https://example.invalid/avatar.jpg","cities":[{"id":1,"name":"Riyadh"}]}}"#)
            case "/api/cities":
                return (200, #"{"key":"success","data":[{"id":1,"name":"Riyadh"}]}"#)
            case "/api/update-profile":
                precondition(request.httpMethod == "POST" && request.url!.query == nil)
                let fields = body(request)
                precondition(fields.contains("name=\"_method\"\r\n\r\nput\r\n"))
                precondition(fields.contains("name=\"birth_date\"\r\n\r\n2000-05-15\r\n"))
                precondition(fields.contains("name=\"name\"\r\n\r\nEdited name\r\n"))
                precondition(fields.contains("name=\"email\"\r\n\r\nuser@example.com\r\n"))
                return (200, #"{"key":"success","data":{"id":1,"name":"Saved profile","birth_date":"15 مايو 2000","email":"user@example.com","phone":"551234567","image":"https://example.invalid/avatar.jpg","cities":[{"id":1,"name":"Riyadh"}]}}"#)
            default: preconditionFailure("Unexpected profile request")
            }
        }
        let loaded = await model.loadProfile()
        precondition(loaded && model.profileLoaded && model.profile.name == "Loaded profile")
        precondition(model.profileImageRevision != cachedRevision)
        precondition(model.profile.hasBirthday && AccountBirthDate.apiFormatter.string(from: model.profile.birthday) == "2000-05-15")
        precondition(UserDefaults.user?.image == model.profile.imageURL)
        await model.loadProfileCities()
        var draft = model.profile; draft.name = "Edited name"
        let loadedRevision = model.profileImageRevision
        let uploadedImage = UIImage()
        let updated = await model.saveProfile(draft, image: uploadedImage)
        precondition(updated && model.profile.name == "Saved profile" && session.user?.name == "Saved profile")
        precondition(model.profile.hasBirthday && model.profile.birthday == draft.birthday)
        precondition(model.avatar === uploadedImage && model.profileImageRevision != loadedRevision)
        precondition(UserDefaults.user?.name == "Saved profile" && UserDefaults.user?.image == "https://example.invalid/avatar.jpg")
        precondition(profileRequests == ["/api/profile", "/api/cities", "/api/update-profile"])
        AccountMock.handler = { request in
            precondition(request.url!.path == "/api/update-profile")
            return (422, #"{"key":"fail","msg":"Profile rejected"}"#)
        }
        let rejectedProfile = await model.saveProfile(draft, image: nil)
        precondition(!rejectedProfile && model.profile.name == "Saved profile" && requests.error == "Profile rejected")
        AccountMock.handler = { request in
            precondition(request.url!.path == "/api/profile")
            return (500, #"{"key":"fail","msg":"Profile unavailable"}"#)
        }
        let failedLoad = await model.loadProfile()
        precondition(!failedLoad && !model.profileLoaded)
        let savedWithoutLoad = await model.saveProfile(draft, image: nil)
        precondition(!savedWithoutLoad)
        AccountMock.handler = { request in
            precondition(request.url!.path == "/api/payment-cards")
            return (200, "{\"key\":\"success\",\"data\":[\(cardJSON)]}")
        }
        await payments.loadCards()
        precondition(payments.cards.count == 1 && payments.cards[0].nickname == "Daily")
        AccountMock.handler = { _ in (422, #"{"key":"fail","msg":"Rename rejected"}"#) }
        let renamed = await payments.renameCard(42, name: "Travel")
        precondition(!renamed && payments.cards[0].nickname == "Daily" && requests.error == "Rename rejected")
        AccountMock.handler = { request in
            if request.url!.path == "/api/payment-cards" {
                return (200, "{\"key\":\"success\",\"data\":[\(cardJSON.replacingOccurrences(of: "Daily", with: "Travel"))]}")
            }
            precondition(request.url!.path == "/api/payment-cards/42/rename")
            return (200, #"{"key":"success"}"#)
        }
        let accepted = await payments.renameCard(42, name: "Travel")
        precondition(accepted && payments.cards[0].nickname == "Travel" && requests.error == nil)
        try await PaymentTests.run(service: service, session: session)
        ProfileBirthDateTests.run()
        await MoreStatsTests.run(service: service, session: session)
        await MoreCashbackTests.run(service: service, session: session)
        await FeatureViewModelTests.run(service: service, session: session)
        try await NotificationTests.run(client: client, session: session)
        try await AccountSettingsTests.run(client: client, session: session)
        try await SupportTicketTests.run(client: client)
        account.resetSession(); precondition(tickets.tickets.isEmpty && payments.cards.isEmpty && requests.error == nil)
        precondition(!AccountValidation.validExpiry("13/30"))
        precondition(AccountValidation.validEmail("name@example.com") && !AccountValidation.validEmail("name@"))
        precondition(AccountValidation.validPasswordChange(current: "old123", new: "new456", confirmation: "new456"))
        try await AccountLifecycleTests.run()
        print("PASS: account multipart uploads, card metadata, authenticated requests, method overrides, language, rejected mutations, notification decoding, missing sessions and support-ticket APIs")
    }
    static func body(_ request: URLRequest) -> String {
        var data = request.httpBody ?? Data()
        if let stream = request.httpBodyStream {
            stream.open(); defer { stream.close() }
            var buffer = [UInt8](repeating: 0, count: 1024)
            while true { let n = stream.read(&buffer, maxLength: buffer.count); if n <= 0 { break }; data.append(contentsOf: buffer.prefix(n)) }
        }
        return String(decoding: data, as: UTF8.self)
    }
}
