import Foundation
import Combine

@MainActor
final class AccountDeleteViewModel: ObservableObject {

    @Published var step = AccountDeletionStep.introduction
    @Published var reasons: Set<String> = []
    let reasonKeys = AccountDeletionReason.all.map(\.id)

    let requests: AccountRequestController
    private var deleting = false

    init(requests: AccountRequestController) { self.requests = requests }

    func deleteAccount() async -> Bool {
        guard !deleting, step != .completed else { return false }
        deleting = true
        step = .processing
        defer { deleting = false }

        let deleted = await requests.run { token, _ in
            try await requests.client.perform(
                AccountEndpoints.deleteAccount(token: token), language: requests.language)
        }
        if deleted {
            // The request controller has verified this is still the session that requested deletion.
            UserDefaults.clearAuthentication()
            reasons.removeAll()
            step = .completed
        } else {
            step = .confirmation
        }
        return deleted
    }

}
