import Foundation

@MainActor
enum MoreCashbackTests {
    static func run(service: LOHAccountService, session: AuthSession) async {
        let account = MoreAccountStore(service: service, session: session)
        let model = account.more
        precondition(model.cashback == nil)
        var calls = 0
        var status = 200
        var response = #"{"key":"success","msg":"تم الإرسال بنجاح","data":{"total":0,"settlements":[]}}"#
        AccountMock.handler = { request in
            calls += 1
            precondition(request.httpMethod == "GET" && request.url!.path == "/api/cash-back")
            precondition(request.url!.query == nil && AccountTests.body(request).isEmpty)
            precondition(request.value(forHTTPHeaderField: "Authorization") == "Bearer test")
            precondition(request.value(forHTTPHeaderField: "lang") == "en")
            return (status, response)
        }
        let loaded = await model.loadCashback()
        precondition(loaded && calls == 1 && model.cashback?.total == 0)
        response = #"{"key":"success","data":{"total":24.5,"settlements":[]}}"#
        let refreshed = await model.loadCashback()
        precondition(refreshed && calls == 2 && model.cashback?.total == 24.5)
        status = 503
        response = #"{"key":"fail","msg":"Cashback unavailable"}"#
        let failed = await model.loadCashback()
        precondition(!failed && model.cashback?.total == 24.5 && account.requests.error == "Cashback unavailable")
        let fresh = MoreViewModel(requests: account.requests)
        let firstLoadFailed = await fresh.loadCashback()
        precondition(!firstLoadFailed && fresh.cashback == nil)
        status = 200
        response = #"{"key":"success","data":{"settlements":[]}}"#
        let malformed = await model.loadCashback()
        precondition(!malformed && model.cashback?.total == 24.5)
        response = #"{"key":"success","data":{"total":0,"settlements":[]}}"#
        let retried = await model.loadCashback()
        precondition(retried && model.cashback?.total == 0 && account.requests.error == nil)
        account.resetSession()
        precondition(model.cashback == nil)
        let suite = "LOH.CashbackTests." + UUID().uuidString
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let guestSession = AuthSession(
            service: LOHAuthService(client: service.client), store: AccountTokenStore(), defaults: defaults)
        let guest = MoreAccountStore(service: service, session: guestSession)
        let callCount = calls
        let guestLoaded = await guest.more.loadCashback()
        precondition(!guestLoaded && calls == callCount && guest.more.cashback == nil)
        print(
            "PASS: authenticated cash-back balance, zero and nonzero totals, refresh, missing data, failed requests, retry and session reset"
        )
    }
}
