import Foundation
import Combine

final class VerificationCodeViewModel: BaseViewModel {
    let phone: String
    let countryCode: String
    let type: AuthVerificationType
    let registration: UserRegisterModel?
    @Published var code = ""
    @Published private(set) var remainingSeconds = 60
    @Published private(set) var canResendCode = false
    @Published private(set) var submitting = false
    @Published var inlineError = ""
    @Published var registerMessage: BaseResponse<User>?
    @Published var authResponse: APIEnvelope<APIUser>?
    @Published private(set) var accountCreated = false
    @Published var registerModel = UserRegisterModel()
    private var verifiedRegistration = false
    private var resendAvailableAt: Date?
    private var timer: Timer?

    let isVerifyAndSignupAsUser = PassthroughSubject<BaseResponse<User>, Never>()
    let isVerifyUserLogin = PassthroughSubject<BaseResponse<User>, Never>()
    let isResendCode = PassthroughSubject<BaseResponse<User>, Never>()

    init(phone: String, countryCode: String, type: AuthVerificationType,
         registration: UserRegisterModel? = nil, responseHandler: ResponseHandler = DefaultResponseHandler()) {
        self.phone = phone; self.countryCode = countryCode; self.type = type; self.registration = registration
        super.init(responseHandler: responseHandler)
    }
    deinit { timer?.invalidate() }
    var formattedRemainingTime: String { String(format: "%02d:%02d", remainingSeconds / 60, remainingSeconds % 60) }

    func startTimer() {
        resendAvailableAt = Date().addingTimeInterval(60)
        resumeTimer()
    }
    func resumeTimer() {
        if resendAvailableAt == nil { resendAvailableAt = Date().addingTimeInterval(60) }
        stopTimer()
        updateCountdown()
        guard !canResendCode else { return }
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in self?.updateCountdown() }
    }
    func updateCountdown(now: Date = Date()) {
        remainingSeconds = max(0, Int(ceil((resendAvailableAt ?? now).timeIntervalSince(now))))
        canResendCode = remainingSeconds == 0
        if canResendCode { stopTimer() }
    }
    func stopTimer() { timer?.invalidate(); timer = nil }
}

@MainActor extension VerificationCodeViewModel {
    func handleConfirm() {
        guard !submitting else { return }
        code = AuthInput.normalizedDigits(code, limit: 4)
        guard code.count == 4 else { inlineError = "auth.codeError".localized; return }
        guard case .loginAsUser = type else { inlineError = "api.unavailable".localized; return }
        guard let deviceID = FCMDeviceIdentity.current else {
            inlineError = APIError.pushNotificationTokenUnavailable.localizedDescription ?? ""
            return
        }
        inlineError = ""
        submitting = true
        Task {
            defer { submitting = false }
            do {
                let response: APIEnvelope<APIUser> = try await DefaultResponseHandler().send(
                    AuthEndpoints.activate(phone: phone,
                        countryCode: countryCode.replacingOccurrences(of: "+", with: ""), code: code,
                        deviceID: deviceID), language: AppLanguageManager.shared.apiLanguage)
                accountCreated = registration != nil
                code = ""
                authResponse = response
            } catch { inlineError = error.localizedDescription }
        }
    }
    func handleResend() {
        guard canResendCode, !submitting else { return }
        guard case .loginAsUser = type else { inlineError = "api.unavailable".localized; return }
        submitting = true; inlineError = ""
        Task {
            defer { submitting = false }
            do {
                try await DefaultResponseHandler().perform(
                    AuthEndpoints.resendCode(phone: phone, countryCode: countryCode.trimmedPlus),
                    language: AppLanguageManager.shared.apiLanguage)
                code = ""; startTimer()
            } catch { inlineError = error.localizedDescription }
        }
    }
}
