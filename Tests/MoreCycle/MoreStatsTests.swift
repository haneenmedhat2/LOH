import Foundation

@MainActor
enum MoreStatsTests {
    static func run(service: LOHAccountService, session: AuthSession) async {
        let account = MoreAccountStore(service: service, session: session)
        let model = account.more
        precondition(model.stats == nil && model.requests === account.requests)
        var calls = 0
        var status = 200
        var response = #"{"key":"success","data":{"used_offers_count":9,"orders_count":27,"member_since":"أكتوبر 2026"}}"#
        AccountMock.handler = { request in
            calls += 1
            precondition(request.httpMethod == "GET" && request.url!.path == "/api/user-stats")
            precondition(request.url!.query == nil && AccountTests.body(request).isEmpty)
            precondition(request.value(forHTTPHeaderField: "Authorization") == "Bearer test")
            precondition(request.value(forHTTPHeaderField: "lang") == "en")
            return (status, response)
        }

        let loaded = await model.loadStats()
        precondition(loaded && calls == 1 && account.requests.error == nil)
        precondition(model.stats?.usedOffersCount == 9 && model.stats?.ordersCount == 27)
        precondition(model.stats?.memberSince == "أكتوبر 2026")

        response = #"{"key":"success","data":{"used_offers_count":0,"orders_count":0,"member_since":"October 2026"}}"#
        let refreshed = await model.loadStats()
        precondition(refreshed && calls == 2 && model.stats?.usedOffersCount == 0 && model.stats?.ordersCount == 0)
        precondition(model.stats?.memberSince == "October 2026")
        let cached = model.stats

        status = 503
        response = #"{"key":"fail","msg":"Stats unavailable"}"#
        let failed = await model.loadStats()
        precondition(!failed && model.stats == cached && account.requests.error == "Stats unavailable")
        let fresh = MoreViewModel(requests: account.requests)
        let firstLoadFailed = await fresh.loadStats()
        precondition(!firstLoadFailed && fresh.stats == nil)

        status = 200
        response = #"{"key":"success","data":{"used_offers_count":5,"member_since":"October 2026"}}"#
        let malformed = await model.loadStats()
        precondition(!malformed && model.stats == cached && account.requests.error != nil)
        response = #"{"key":"success","data":{"used_offers_count":12,"orders_count":30,"member_since":"October 2026"}}"#
        let retried = await model.loadStats()
        precondition(retried && model.stats?.usedOffersCount == 12 && model.stats?.ordersCount == 30)
        precondition(account.requests.error == nil)

        account.resetSession()
        precondition(model.stats == nil)
        let suite = "LOH.MoreStatsTests." + UUID().uuidString
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let guestSession = AuthSession(service: LOHAuthService(client: service.client), store: AccountTokenStore(), defaults: defaults)
        let guest = MoreAccountStore(service: service, session: guestSession)
        let callCount = calls
        let guestLoaded = await guest.more.loadStats()
        precondition(!guestLoaded && calls == callCount && guest.more.stats == nil)
        print("PASS: authenticated user-stats, nonzero and zero counts, membership dates, refresh, cached failures, malformed responses and session reset")
    }
}
