import Foundation
import Combine

@MainActor
final class AccountLanguageViewModel: ObservableObject {
    let options = AccountLanguageOption.available
    @Published var languageChangeConfirmed = false
    let requests: AccountRequestController

    init(requests: AccountRequestController) { self.requests = requests }

    func changeLanguage(_ value: String) async -> Bool {
        guard ["ar", "en"].contains(value) else { return false }

        // Guests only need the local language preference. The account endpoint
        // requires an authenticated token and must not be called in guest mode.
        guard UserDefaults.accessToken != nil else { return true }

        return await requests.run { token, _ in
            try await requests.client.perform(
                AccountEndpoints.changeLanguage(value, token: token), language: value)
        }
    }

    func resetSession() {
        languageChangeConfirmed = false
    }
}
