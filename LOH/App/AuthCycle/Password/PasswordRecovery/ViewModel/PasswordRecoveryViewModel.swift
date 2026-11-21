import Foundation
import Combine

@MainActor
final class PasswordRecoveryViewModel: ObservableObject {
    @Published var phone = ""
    @Published private(set) var errorKey: String?
    @Published private(set) var submitting = false
    private let client: DefaultResponseHandler

    init(client: DefaultResponseHandler = DefaultResponseHandler()) { self.client = client }

    var validPhone: Bool {
        AccountValidation.validPhone(phone)
    }

    func requestCode(countryCode: String) async -> Bool {
        guard !submitting else { return false }
        guard validPhone else { errorKey = "recovery.invalidPhone"; return false }
        submitting = true; errorKey = nil
        defer { submitting = false }
        do {
            let normalizedPhone = AccountValidation.phoneDigits(phone)
            try await client.perform(
                AuthEndpoints.sendRecoveryCode(phone: normalizedPhone, countryCode: countryCode),
                language: AppLanguageManager.currentLanguage())
            phone = normalizedPhone
            return true
        } catch {
            errorKey = error.localizedDescription
            return false
        }
    }
}
