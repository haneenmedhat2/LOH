import Foundation
import Combine

@MainActor
final class AccountPasswordViewModel: ObservableObject {

    @Published var form = AccountPasswordForm()
    @Published private(set) var completed = false

    func submit() async {
        guard form.valid else { return }
        if await changePassword(current: form.current, password: form.password) {
            form = AccountPasswordForm()
            completed = true
        }
    }

    private let requests: AccountRequestController

    init(requests: AccountRequestController) { self.requests = requests }

    private func changePassword(current: String, password: String) async -> Bool {
        await requests.run { token, _ in
            try await requests.client.perform(
                AccountEndpoints.updatePassword(current: current, new: password, token: token),
                language: requests.language)
        }
    }

}
