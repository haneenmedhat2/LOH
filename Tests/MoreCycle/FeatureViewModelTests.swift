import Foundation

@MainActor
enum FeatureViewModelTests {
    static func run(service: LOHAccountService, session: AuthSession) async {
        let account = MoreAccountStore(service: service, session: session)
        let requests = account.requests
        let join = AccountJoinViewModel(requests: requests)
        let password = AccountPasswordViewModel(requests: requests)
        var calls: [String] = []
        AccountMock.handler = { request in
            calls.append(request.url!.path)
            let body = AccountTests.body(request)
            switch request.url!.path {
            case "/api/join-us":
                precondition(request.httpMethod == "POST")
                precondition(body.contains("name=\"company_name\"\r\n\r\nBusiness\r\n"))
                precondition(body.contains("name=\"phone\"\r\n\r\n512345678\r\n"))
            case "/api/update-password":
                precondition(request.httpMethod == "POST" && request.url!.query == "_method=patch")
                precondition(body.contains("name=\"old_password\"\r\n\r\nold123\r\n"))
                precondition(body.contains("name=\"password\"\r\n\r\nnew456\r\n"))
            default: preconditionFailure("Unexpected form request")
            }
            return (200, #"{"key":"success"}"#)
        }
        await join.submit()
        await password.submit()
        precondition(calls.isEmpty && !join.submitted && !password.completed)
        join.form = AccountJoinForm(business: "Business", name: "Contact", phone: "512345678", email: "user@example.com", details: "Notes")
        await join.submit()
        precondition(join.submitted && calls == ["/api/join-us"])
        password.form = AccountPasswordForm(current: "old123", password: "new456", confirmation: "new456")
        await password.submit()
        precondition(password.completed && password.form.current.isEmpty && password.form.password.isEmpty && password.form.confirmation.isEmpty)
        precondition(calls == ["/api/join-us", "/api/update-password"])

        let failedJoin = AccountJoinViewModel(requests: requests)
        failedJoin.form = join.form
        AccountMock.handler = { _ in (422, #"{"key":"fail","msg":"Join rejected"}"#) }
        await failedJoin.submit()
        precondition(!failedJoin.submitted && requests.error == "Join rejected")

        // All shared feature VMs use one session scope. A completion from the
        // previous scope must not restore cleared feature data after logout.
        var release: CheckedContinuation<Void, Never>?
        var operation: Task<Bool, Never>?
        var appliedStaleCompletion = false
        await withCheckedContinuation { ready in
            operation = Task {
                await requests.run { token, generation in
                    await withCheckedContinuation { continuation in
                        release = continuation
                        ready.resume()
                    }
                    try requests.check(token, generation)
                    appliedStaleCompletion = true
                }
            }
        }
        precondition(requests.busy)
        account.language.languageChangeConfirmed = true
        account.resetSession()
        release?.resume()
        let succeeded = await operation!.value
        precondition(!succeeded && !appliedStaleCompletion && !requests.busy && requests.error == nil)
        precondition(account.tickets.tickets.isEmpty && account.payments.cards.isEmpty && !account.profile.profileLoaded)
        precondition(!account.language.languageChangeConfirmed && account.tickets.filter.search.isEmpty)
        print("PASS: separate form view models, validation, rejected submission, secret clearing and session-scoped completion")
    }
}
