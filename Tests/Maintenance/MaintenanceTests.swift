import Foundation

@main
struct MaintenanceTests {
    struct Offers: Decodable { let coupons: [Int] }
    static let success = #"{"key":"success","data":{"coupons":[17]}}"#
    static let maintenance = #"{"key":"maintenance_mode","data":{}}"#

    @MainActor
    static func waitUntil(_ condition: () -> Bool) async throws {
        for _ in 0..<1_000 {
            if condition() { return }
            try await Task.sleep(nanoseconds: 1_000_000)
        }
        fatalError("Timed out waiting for maintenance presentation")
    }

    @MainActor
    static func main() async throws {
        try await emptyPayloadsAndRecovery()
        try await ordinaryResponse()
        try await failedRetries()
        try await cancellation()
        try await writesAreNotReplayed()
        try await concurrentRequests()
        try await staleProbe()
        print("PASS: maintenance decoding, recovery, failures, cancellation, write safety and concurrency")
    }

    @MainActor
    static func emptyPayloadsAndRecovery() async throws {
        for field in [#", "data": {}"#, #", "data": []"#, #", "data": null"#,
                      #", "data": """#, "", #", "data": {"title":"Server title","is_maintenance":true}"#] {
            let json = #"{"key":"maintenance_mode""# + field + "}"
            let network = StubNetwork([json, success, success])
            let state = MaintenanceViewModel()
            let handler = DefaultResponseHandler(networkExecuter: network, maintenance: state)
            let task = Task {
                try await handler.data(from: Endpoint<APIEnvelope<Offers>>(path: "search-offers"), language: "ar")
            }
            try await waitUntil { state.isPresented }
            assert(!state.isRetrying)
            await state.retry()
            let offers = try await task.value
            assert(offers.coupons == [17])
            assert(!state.isPresented && !state.isRetrying)
            let calls = await network.calls
            assert(calls.count == 3 && calls.allSatisfy { $0.method == .get })
        }
    }

    @MainActor
    static func ordinaryResponse() async throws {
        let network = StubNetwork([success])
        let state = MaintenanceViewModel()
        let result = try await DefaultResponseHandler(networkExecuter: network, maintenance: state)
            .data(from: Endpoint<APIEnvelope<Offers>>(path: "search-offers"), language: "en")
        assert(result.coupons == [17] && !state.isPresented)
        assert(!APIResponseStatus.isMaintenance(Data(#"{"data":{}}"#.utf8)))
    }

    @MainActor
    static func failedRetries() async throws {
        let network = StubNetwork([maintenance, "not JSON", maintenance, success, success])
        let state = MaintenanceViewModel()
        let handler = DefaultResponseHandler(networkExecuter: network, maintenance: state)
        let task = Task { try await handler.get(Endpoint<APIEnvelope<Offers>>(path: "search-offers")) }
        try await waitUntil { state.isPresented }
        await state.retry()
        assert(state.isPresented && state.errorMessage == "maintenance.retryFailed")
        await state.retry()
        assert(state.isPresented && state.errorMessage == "maintenance.stillUnavailable")
        await state.retry()
        _ = try await task.value
        assert(!state.isPresented && state.errorMessage == nil)

        let offline = MaintenanceViewModel()
        let offlineNetwork = StubNetwork([maintenance])
        let pending = Task {
            try await DefaultResponseHandler(networkExecuter: offlineNetwork, maintenance: offline)
                .get(Endpoint<APIEnvelope<Offers>>(path: "search-offers"))
        }
        try await waitUntil { offline.isPresented }
        await offline.retry()
        assert(offline.isPresented && offline.errorMessage == "maintenance.retryFailed")
        pending.cancel()
        _ = await pending.result
    }

    @MainActor
    static func cancellation() async throws {
        let state = MaintenanceViewModel()
        let network = StubNetwork([maintenance, success])
        let task = Task {
            try await DefaultResponseHandler(networkExecuter: network, maintenance: state)
                .get(Endpoint<APIEnvelope<Offers>>(path: "search-offers"))
        }
        try await waitUntil { state.isPresented }
        task.cancel()
        do {
            _ = try await task.value
            fatalError("Cancelled requests must not resume")
        } catch is CancellationError {}
        await state.retry()
        let calls = await network.calls
        assert(calls.count == 2) // Only the availability probe; no cancelled request replay.
    }

    @MainActor
    static func writesAreNotReplayed() async throws {
        for method in [RequestMethod.post, .patch, .put, .delete] {
            let state = MaintenanceViewModel()
            let network = StubNetwork([maintenance, success])
            let task = Task {
                try await DefaultResponseHandler(networkExecuter: network, maintenance: state)
                    .get(Endpoint<APIEnvelope<APIEmpty>>(
                        method: method, path: "update-profile", body: ["name": "Test"]))
            }
            try await waitUntil { state.isPresented }
            await state.retry()
            do {
                _ = try await task.value
                fatalError("The failed write must remain unsubmitted")
            } catch APIError.interruptedByMaintenance {}
            let calls = await network.calls
            assert(calls.count == 2)
            assert(calls[0].method == method)
            assert(calls[1].method == .get && calls[1].path == "search-offers" && !calls[1].hasBody)
        }
    }

    @MainActor
    static func concurrentRequests() async throws {
        let state = MaintenanceViewModel()
        let network = StubNetwork([maintenance, maintenance, success, success, success])
        let handler = DefaultResponseHandler(networkExecuter: network, maintenance: state)
        let first = Task { try await handler.get(Endpoint<APIEnvelope<Offers>>(path: "search-offers")) }
        let second = Task { try await handler.get(Endpoint<APIEnvelope<Offers>>(path: "home-page")) }
        try await waitUntil { state.isPresented }
        // Let both detected responses register before retrying.
        try await Task.sleep(nanoseconds: 20_000_000)
        await state.retry()
        _ = try await (first.value, second.value)
        assert(!state.isPresented)
    }

    @MainActor
    static func staleProbe() async throws {
        let state = MaintenanceViewModel()
        var finishProbe: CheckedContinuation<Bool, Never>?
        let first = Task {
            try await state.waitForRecovery {
                await withCheckedContinuation { finishProbe = $0 }
            }
        }
        try await waitUntil { state.isPresented }
        let retry = Task { await state.retry() }
        try await waitUntil { finishProbe != nil }
        let second = Task { try await state.waitForRecovery { true } }
        try await Task.sleep(nanoseconds: 20_000_000)
        await state.retry() // Must not start a duplicate check while one is pending.
        finishProbe?.resume(returning: true)
        await retry.value
        assert(state.isPresented && state.errorMessage == "maintenance.stillUnavailable")
        first.cancel()
        second.cancel()
        _ = await (first.result, second.result)
    }
}
