import Foundation

/// Controlled responses let tests change sessions while a destructive request is in flight.
final class AccountLifecycleMock: URLProtocol {
    @MainActor static var onStart: ((AccountLifecycleMock) -> Void)?
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        Task { @MainActor in
            guard let onStart = Self.onStart else { preconditionFailure("Unexpected lifecycle request") }
            onStart(self)
        }
    }
    override func stopLoading() {}

    func respond(status: Int = 200, body: String) {
        client?.urlProtocol(self, didReceive: HTTPURLResponse(url: request.url!, statusCode: status,
                                                            httpVersion: nil, headerFields: nil)!,
                            cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Data(body.utf8))
        client?.urlProtocolDidFinishLoading(self)
    }
}

@MainActor
enum AccountLifecycleTests {
    static func run() async throws {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [AccountLifecycleMock.self]
        let transport = URLSession(configuration: configuration)
        defer { transport.invalidateAndCancel() }
        let client = APIClient(baseURL: URL(string: "https://example.invalid/api/")!, session: transport)
        let suite = "LOH.AccountLifecycleTests." + UUID().uuidString
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let session = AuthSession(service: LOHAuthService(client: client, language: { "ar" }),
                                  store: AccountTokenStore(), defaults: defaults)
        let requests = AccountRequestController(service: LOHAccountService(client: client), session: session)

        // No token must not send either authenticated service.
        let missing = AccountDeleteViewModel(requests: requests)
        let deletedWithoutSession = await missing.deleteAccount()
        precondition(!deletedWithoutSession)
        precondition(missing.step == .confirmation && requests.error != nil)
        try await session.logout()
        precondition(session.token == nil)

        try signIn(session)
        let deletion = AccountDeleteViewModel(requests: requests)
        deletion.reasons.insert("settings.Delete service")
        for (status, body) in [(503, #"{"key":"fail","msg":"Delete unavailable"}"#),
                               (200, #"{"key":"fail","msg":"Deletion rejected"}"#),
                               (200, "not-json")] {
            let (request, operation) = await start { await deletion.deleteAccount() }
            assertRequest(request, path: "delete-account", token: "lifecycle-token", language: "en")
            precondition(deletion.step == .processing && requests.busy)
            let duplicate = await deletion.deleteAccount()
            precondition(!duplicate) // A second tap cannot issue another DELETE.
            precondition(deletion.step == .processing && requests.busy)
            request.respond(status: status, body: body)
            let deleted = await operation.value
            precondition(!deleted && deletion.step == .confirmation && requests.error != nil && !requests.busy)
            precondition(session.isAuthenticated && session.token == "lifecycle-token" && session.user?.id == 10)
            precondition(UserDefaults.isLogin && UserDefaults.user?.id == 10 && !deletion.reasons.isEmpty)
        }

        let (deleteRequest, deleteOperation) = await start { await deletion.deleteAccount() }
        assertRequest(deleteRequest, path: "delete-account", token: "lifecycle-token", language: "en")
        deleteRequest.respond(body: #"{"key":"success","msg":"Account deleted"}"#) // Collection has no data.
        let deleted = await deleteOperation.value
        precondition(deleted && deletion.step == .completed && deletion.reasons.isEmpty)
        precondition(session.token == nil && session.user == nil && session.stage == .signedOut)
        precondition(!UserDefaults.isLogin && UserDefaults.user == nil && AuthPreviewSession.user == nil)
        precondition(!requests.busy && requests.error == nil)
        let repeated = await deletion.deleteAccount()
        precondition(!repeated) // Completed screen cannot resubmit.

        // Late deletion success cannot delete a newly authenticated local session.
        try signIn(session)
        let staleDeletion = AccountDeleteViewModel(requests: requests)
        let (staleRequest, staleOperation) = await start { await staleDeletion.deleteAccount() }
        try signIn(session, token: "replacement-token", id: 11)
        requests.resetSession()
        staleRequest.respond(body: #"{"key":"success"}"#)
        let staleDeleted = await staleOperation.value
        precondition(!staleDeleted && staleDeletion.step != .completed && requests.error == nil)
        precondition(session.token == "replacement-token" && session.isAuthenticated && session.user?.id == 11)

        try signIn(session)
        let (failedLogout, failedLogoutOperation) = await start { await logout(session) }
        assertRequest(failedLogout, path: "sign-out", token: "lifecycle-token", language: "ar")
        failedLogout.respond(status: 503, body: #"{"key":"fail","msg":"Sign out unavailable"}"#)
        guard case .failure(let error) = await failedLogoutOperation.value else {
            preconditionFailure("Rejected logout must not report success")
        }
        precondition(error.localizedDescription == "Sign out unavailable")
        precondition(session.isAuthenticated && session.token == "lifecycle-token" && UserDefaults.isLogin)

        let (logoutRequest, logoutOperation) = await start { await logout(session) }
        assertRequest(logoutRequest, path: "sign-out", token: "lifecycle-token", language: "ar")
        logoutRequest.respond(body: #"{"key":"success","msg":"Signed out"}"#)
        guard case .success = await logoutOperation.value else { preconditionFailure("Logout should succeed") }
        precondition(session.token == nil && session.user == nil && session.stage == .signedOut)
        precondition(UserDefaults.user == nil && !UserDefaults.isLogin && AuthPreviewSession.user == nil)

        try signIn(session)
        let (oldLogout, oldLogoutOperation) = await start { await logout(session) }
        try signIn(session, token: "replacement-token", id: 11)
        oldLogout.respond(body: #"{"key":"success"}"#)
        guard case .failure(let staleError) = await oldLogoutOperation.value, staleError is CancellationError else {
            preconditionFailure("Old logout must cancel instead of navigating the new account to login")
        }
        precondition(session.token == "replacement-token" && session.isAuthenticated && UserDefaults.user?.id == 11)
        session.clear()
        print("PASS: DELETE delete-account/sign-out contracts, confirmation state, duplicate protection, failures, session cleanup and stale responses")
    }

    private static func signIn(_ session: AuthSession, token: String = "lifecycle-token", id: Int = 10) throws {
        let data = Data(#"{"key":"success","data":{"id":\#(id),"token":"\#(token)","name":"Account"}}"#.utf8)
        try session.accept(JSONDecoder().decode(APIEnvelope<APIUser>.self, from: data))
    }

    private static func logout(_ session: AuthSession) async -> Result<Void, Error> {
        do { try await session.logout(); return .success(()) }
        catch { return .failure(error) }
    }

    private static func start<T>(_ operation: @escaping @MainActor () async -> T) async -> (AccountLifecycleMock, Task<T, Never>) {
        var task: Task<T, Never>!
        let request = await withCheckedContinuation { continuation in
            AccountLifecycleMock.onStart = { continuation.resume(returning: $0) }
            task = Task { await operation() }
        }
        AccountLifecycleMock.onStart = nil
        return (request, task)
    }

    private static func assertRequest(_ pending: AccountLifecycleMock, path: String, token: String, language: String) {
        let request = pending.request
        precondition(request.httpMethod == "DELETE" && request.url?.path == "/api/" + path)
        precondition(request.url?.query == nil && AccountTests.body(request).isEmpty)
        precondition(request.value(forHTTPHeaderField: "Authorization") == "Bearer " + token)
        precondition(request.value(forHTTPHeaderField: "lang") == language)
        precondition(request.value(forHTTPHeaderField: "Accept") == "application/json")
    }
}
