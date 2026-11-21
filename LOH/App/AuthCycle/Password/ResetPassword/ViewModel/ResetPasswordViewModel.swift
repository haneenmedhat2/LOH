import Foundation
import Combine

@MainActor
final class ResetPasswordViewModel: ObservableObject {
    let phone: String
    let countryCode: String
    let code: String
    @Published var password = ""
    @Published var confirmation = ""
    @Published private(set) var errorKey: String?
    @Published private(set) var submitting = false
    private let client: DefaultResponseHandler

    init(phone: String, countryCode: String, code: String,
         client: DefaultResponseHandler = DefaultResponseHandler()) {
        self.phone = phone
        self.countryCode = countryCode
        self.code = code
        self.client = client
    }

    var validPassword: Bool {
        password.count >= 6 && password.count <= 100
            && !password.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && password == confirmation
    }

    func save() async -> Bool {
        guard !submitting else { return false }
        guard validPassword else { errorKey = "recovery.passwordError"; return false }
        submitting = true; errorKey = nil
        defer { submitting = false }
        do {
            try await client.perform(
                AuthEndpoints.resetPassword(phone: phone, countryCode: countryCode, password: password),
                language: AppLanguageManager.currentLanguage())
            return true
        } catch {
            errorKey = error.localizedDescription
            return false
        }
    }
}
