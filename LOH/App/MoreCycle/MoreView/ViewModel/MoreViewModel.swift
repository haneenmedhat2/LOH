import Foundation
import Combine

@MainActor
final class MoreViewModel: ObservableObject {
    @Published private(set) var stats: MoreUserStats?
    @Published private(set) var cashback: MoreCashbackBalance?
    let requests: AccountRequestController

    init(requests: AccountRequestController) { self.requests = requests }

    @discardableResult
    func loadStats() async -> Bool {
        guard !Task.isCancelled else { return false }
        return await requests.run { token, generation in
            let result: MoreUserStats = try await requests.client.data(
                from: AccountEndpoints.userStats(token: token), language: requests.language)
            try requests.check(token, generation)
            stats = result
        }
    }

    @discardableResult
    func loadCashback() async -> Bool {
        guard !Task.isCancelled else { return false }
        return await requests.run { token, generation in
            let result: MoreCashbackBalance = try await requests.client.data(
                from: AccountEndpoints.cashback(token: token), language: requests.language)
            try requests.check(token, generation)
            cashback = result
        }
    }

    func resetSession() {
        stats = nil
        cashback = nil
    }
}
