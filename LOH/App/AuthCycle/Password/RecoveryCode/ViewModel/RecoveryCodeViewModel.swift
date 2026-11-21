import Foundation
import Combine

@MainActor
final class RecoveryCodeViewModel: ObservableObject {
    static let title = "recovery.enterCode"
    static let message = "recovery.codeMessage"
    let phone: String
    let countryCode: String
    @Published var code = "" { didSet { errorKey = nil } }
    @Published private(set) var errorKey: String?
    @Published private(set) var resendAt: Date?
    @Published private(set) var submitting = false
    private let client: DefaultResponseHandler

    init(phone: String, countryCode: String, client: DefaultResponseHandler = DefaultResponseHandler()) {
        self.phone = phone
        self.countryCode = countryCode
        self.client = client
    }

    func startResendTimer() {
        guard resendAt == nil else { return }
        resendAt = Date().addingTimeInterval(60)
    }

    func resend() async {
        guard !submitting, remainingSeconds() == 0 else { return }
        submitting = true; errorKey = nil
        defer { submitting = false }
        do {
            try await client.perform(
                AuthEndpoints.resendCode(phone: phone, countryCode: countryCode),
                language: AppLanguageManager.currentLanguage())
            resendAt = Date().addingTimeInterval(60)
        } catch { errorKey = error.localizedDescription }
    }

    func activate() async -> Bool {
        guard !submitting else { return false }
        let normalized = AuthInput.normalizedDigits(code)
        guard normalized.count == 4 else { errorKey = "recovery.invalidCode"; return false }
        guard let deviceID = FCMDeviceIdentity.current else {
            errorKey = "api.pushTokenUnavailable"
            return false
        }
        submitting = true; errorKey = nil
        defer { submitting = false }
        do {
            let response: APIEnvelope<APIUser> = try await client.send(
                AuthEndpoints.activate(phone: phone, countryCode: countryCode, code: normalized,
                                       deviceID: deviceID),
                language: AppLanguageManager.currentLanguage())
            guard ["success", "selectCity", "selectInterests"].contains(response.key) else {
                throw APIError.invalidResponse
            }
            code = normalized
            return true
        } catch {
            errorKey = error.localizedDescription
            return false
        }
    }

    func remainingSeconds(now: Date = Date()) -> Int {
        max(0, Int(ceil((resendAt ?? now).timeIntervalSince(now))))
    }
}
