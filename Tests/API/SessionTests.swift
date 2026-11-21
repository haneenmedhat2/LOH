import Foundation

// Host-only persistence stand-ins. Production uses UserDefaults + Keychain.
extension UserDefaults {
    static var user: User?
    static var isLogin = false
}
enum AuthPreviewSession { static var user: User? }
final class MemoryTokenStore: AuthTokenStoring {
    var value: String?
    var failWrites = false
    func read() -> String? { value }
    func write(_ token: String) throws { if failWrites { throw APIError.secureStorage }; value = token }
    func delete() { value = nil }
}
struct FailingRecoveryService: PasswordRecoveryServicing {
    func verifyPasswordRecoveryCode(phone: String, code: String) async throws { throw APIError.server("Invalid OTP") }
    func sendPasswordRecoveryCode(phone: String) async throws { throw APIError.server("SMS failed") }
    func resend(phone: String) async throws { throw APIError.server("SMS failed") }
    func resetPassword(phone: String, password: String) async throws { throw APIError.server("Invalid OTP") }
}

@MainActor enum SessionTests {
    static func run(service: LOHAuthService) async throws {
        let suite = "LOH.SessionTests." + UUID().uuidString
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = MemoryTokenStore()
        store.value = "token-from-deleted-install"
        MockProtocol.handler = { _ in
            preconditionFailure("A fresh install must not request the profile")
        }
        let session = AuthSession(service: service, store: store, defaults: defaults)
        precondition(session.token == nil)
        try await session.restore()
        precondition(session.stage == .signedOut)
        let user = #"{"id":7,"name":"Test","phone":"551234567","token":"session-token","cities":[],"interests":[]}"#
        func response(_ key: String, user: String) throws -> APIEnvelope<APIUser> {
            try JSONDecoder().decode(APIEnvelope<APIUser>.self, from: Data("{\"key\":\"\(key)\",\"data\":\(user)}".utf8))
        }
        do { try session.accept(response("needActive", user: user)); preconditionFailure("Activation must not authenticate") } catch { }
        precondition(session.token == nil && !session.isAuthenticated)
        store.failWrites = true
        do { try session.accept(response("success", user: user)); preconditionFailure("Must not authenticate if token storage fails") } catch { }
        precondition(!session.isAuthenticated)
        store.failWrites = false
        try session.accept(response("selectCity", user: user))
        precondition(session.stage == .cities && !session.isAuthenticated && session.token == "session-token")
        precondition(UserDefaults.user?.token == nil && session.user?.token == nil)
        let cities = #"[{"id":"1","name":"City","is_selected":true}]"#
        let selectedCityUser = "{\"id\":7,\"cities\":\(cities),\"interests\":[]}"
        MockProtocol.handler = { request in
            if request.url!.path == "/api/select-city" { return (200, #"{"key":"success"}"#) }
            return (200, "{\"key\":\"success\",\"data\":\(selectedCityUser)}")
        }
        MockProtocol.handler = { _ in (400, #"{"key":"fail","msg":"Choose a valid city"}"#) }
        do {
            try await session.select(cities: true, ids: [1])
            preconditionFailure("Failed city selection must not open Home")
        } catch { }
        precondition(session.stage == .cities && !session.isAuthenticated)
        MockProtocol.handler = { request in
            if request.url!.path == "/api/select-city" { return (200, #"{"key":"success"}"#) }
            return (200, "{\"key\":\"success\",\"data\":\(selectedCityUser)}")
        }
        try await session.select(cities: true, ids: [1])
        precondition(session.stage == .authenticated && session.isAuthenticated)
        let completeUser = "{\"id\":7,\"cities\":\(cities),\"interests\":\(cities)}"
        MockProtocol.handler = { request in
            if request.url!.path == "/api/select-interest" { return (200, #"{"key":"success"}"#) }
            return (200, "{\"key\":\"success\",\"data\":\(completeUser)}")
        }
        try await session.select(cities: false, ids: [1])
        precondition(session.isAuthenticated && UserDefaults.isLogin)
        let restored = AuthSession(service: service, store: store, defaults: defaults)
        try await restored.restore()
        precondition(restored.isAuthenticated && restored.user?.id == 7)
        MockProtocol.handler = { _ in (503, #"{"key":"exception","msg":"Unavailable"}"#) }
        do { try await restored.restore(); preconditionFailure("Network failure must surface") } catch { }
        precondition(restored.token == "session-token")
        let expiry = NotificationCenter.default.addObserver(forName: .lohSessionExpired, object: nil, queue: nil) { note in
            precondition(note.object as? String == "session-token")
        }
        MockProtocol.handler = { _ in (200, #"{"key":"unauthenticated","msg":"Expired"}"#) }
        do { try await restored.restore(); preconditionFailure("Expired token must fail") } catch { }
        NotificationCenter.default.removeObserver(expiry)
        // The app coordinator handles the notification on the main queue.
        restored.clear()
        precondition(restored.token == nil && restored.stage == .signedOut && UserDefaults.user == nil)
        try session.accept(response("success", user: user))
        MockProtocol.handler = { request in
            precondition(request.url!.path == "/api/sign-out" && request.httpMethod == "DELETE")
            return (200, #"{"key":"success"}"#)
        }
        MockProtocol.handler = { _ in (503, #"{"key":"exception","msg":"Try later"}"#) }
        do { try await session.logout(); preconditionFailure("Failed logout must be reported") } catch { }
        precondition(session.token == "session-token")
        MockProtocol.handler = { _ in (200, #"{"key":"success"}"#) }
        try await session.logout()
        precondition(!session.isAuthenticated && session.token == nil)
        // Simulate deleting app preferences while its Keychain token survives.
        store.value = "surviving-keychain-token"
        defaults.removePersistentDomain(forName: suite)
        let reinstalled = AuthSession(service: service, store: store, defaults: defaults)
        MockProtocol.handler = { _ in
            preconditionFailure("Reinstall must not request the old user's profile")
        }
        try await reinstalled.restore()
        precondition(reinstalled.token == nil && reinstalled.stage == .signedOut)
        reinstalled.continueAsGuest()
        precondition(reinstalled.isGuestBrowsing && reinstalled.token == nil && !reinstalled.isAuthenticated)
        let guestRestored = AuthSession(service: service, store: store, defaults: defaults)
        try await guestRestored.restore()
        precondition(guestRestored.isGuestBrowsing && guestRestored.stage == .signedOut)
        precondition(guestRestored.user == nil && UserDefaults.user == nil && !UserDefaults.isLogin)
        try guestRestored.accept(response("success", user: user))
        precondition(!guestRestored.isGuestBrowsing && guestRestored.isAuthenticated)
        guestRestored.continueAsGuest()
        precondition(guestRestored.token == nil && guestRestored.user == nil && guestRestored.isGuestBrowsing)
        guestRestored.clear()
        precondition(!guestRestored.isGuestBrowsing)
        let signedOutAgain = AuthSession(service: service, store: store, defaults: defaults)
        precondition(!signedOutAgain.isGuestBrowsing && signedOutAgain.token == nil)
        let recovery = PasswordRecoveryModel(previewEnabled: false, service: service)
        recovery.phone = "٠٥٥١٢٣٤٥٦٧"
        MockProtocol.handler = { request in
            precondition(request.url!.path == "/api/forget-password-send-code" && request.httpMethod == "POST")
            precondition(request.url!.query == nil)
            precondition(request.value(forHTTPHeaderField: "Content-Type")?.hasPrefix("multipart/form-data;") == true)
            var data = request.httpBody ?? Data()
            if let stream = request.httpBodyStream {
                stream.open()
                defer { stream.close() }
                var buffer = [UInt8](repeating: 0, count: 1024)
                while stream.hasBytesAvailable {
                    let count = stream.read(&buffer, maxLength: buffer.count)
                    guard count > 0 else { break }
                    data.append(contentsOf: buffer.prefix(count))
                }
            }
            let body = String(data: data, encoding: .utf8) ?? ""
            precondition(body.contains("name=\"phone\"") && body.contains("0551234567"))
            return (200, #"{"key":"success"}"#)
        }
        await recovery.requestCode()
        precondition(recovery.step == .code && recovery.phone == "0551234567")
        recovery.code = "٩٨٧٦"
        MockProtocol.handler = { _ in (400, #"{"key":"fail","msg":"Invalid OTP"}"#) }
        await recovery.continueWithCode()
        precondition(recovery.step == .code && recovery.errorKey == "Invalid OTP" && !recovery.submitting)
        MockProtocol.handler = { request in
            precondition(request.httpMethod == "POST" && request.url!.path == "/api/activate")
            precondition(request.url!.query == "_method=patch")
            let body = requestBody(request)
            for (name, value) in [("code", "9876"), ("phone", "0551234567"), ("country_code", "966"), ("device_type", "ios")] {
                precondition(body.contains("name=\"\(name)\"\r\n\r\n\(value)\r\n"))
            }
            precondition(body.contains("name=\"device_id\""))
            return (200, #"{"key":"selectCity","data":{"id":4474,"token":"recovery-only"}}"#)
        }
        await recovery.continueWithCode()
        precondition(recovery.step == .password && recovery.code == "9876")
        precondition(reinstalled.token == nil && reinstalled.stage == .signedOut)
        recovery.password = "newpassword"; recovery.confirmation = "newpassword"
        MockProtocol.handler = { _ in (400, #"{"key":"fail","msg":"Invalid OTP"}"#) }
        let rejected = await recovery.savePassword()
        precondition(!rejected && recovery.step == .password && recovery.errorKey == "Invalid OTP")
        MockProtocol.handler = { request in
            precondition(request.httpMethod == "POST" && request.url!.path == "/api/reset-password")
            let body = requestBody(request)
            precondition(!body.contains("name=\"code\""))
            for (name, value) in [("phone", "0551234567"), ("password", "newpassword")] {
                precondition(body.contains("name=\"\(name)\"\r\n\r\n\(value)\r\n"))
            }
            return (200, #"{"key":"success"}"#)
        }
        let saved = await recovery.savePassword()
        precondition(saved && recovery.code.isEmpty && recovery.password.isEmpty)
        let failed = PasswordRecoveryModel(previewEnabled: false, service: FailingRecoveryService())
        failed.phone = "551234567"
        await failed.requestCode()
        precondition(failed.step == .phone && failed.errorKey == "SMS failed" && !failed.submitting)
        print("PASS: session stages, secure storage failure, restoration, transient errors, expiry notification, logout and live recovery")
    }

    private static func requestBody(_ request: URLRequest) -> String {
        var data = request.httpBody ?? Data()
        if let stream = request.httpBodyStream {
            stream.open()
            defer { stream.close() }
            var buffer = [UInt8](repeating: 0, count: 1024)
            while true {
                let count = stream.read(&buffer, maxLength: buffer.count)
                guard count > 0 else { break }
                data.append(contentsOf: buffer.prefix(count))
            }
        }
        return String(decoding: data, as: UTF8.self)
    }
}
