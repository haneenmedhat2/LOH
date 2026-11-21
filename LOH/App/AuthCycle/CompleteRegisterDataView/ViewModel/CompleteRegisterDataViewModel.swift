import Foundation
import Combine

final class CompleteRegisterDataViewModel: BaseViewModel {
    @Published var name = ""
    @Published var email = ""
    @Published var password = "" {
        didSet { passwordError = "" }
    }
    @Published var passwordError = ""
    var passwordHasMinimumLength: Bool { password.count >= 6 && password.count <= 100 }
    var passwordHasUppercase: Bool { password.rangeOfCharacter(from: .uppercaseLetters) != nil }
    var passwordHasNumber: Bool { password.rangeOfCharacter(from: .decimalDigits) != nil }
    var isPasswordValid: Bool { passwordHasMinimumLength && passwordHasUppercase && passwordHasNumber }
    @Published var acceptTerms = false
    @Published var phone: String
    @Published var countryCode: String
    @Published var countries: [CountriesDataModel] = []
    @Published var selectedCountry: CountriesDataModel?
    @Published var nameError = ""
    @Published var phoneError = ""
    @Published var emailError = ""
    @Published var termsError = ""
    @Published var submitting = false
    @Published var isRegisterSuccess = false
    @Published var resultUser: User?
    let verificationRequested = PassthroughSubject<UserRegisterModel, Never>()
    let phoneAlreadyVerified: Bool

    init(phone: String = "", countryCode: String = "+966", phoneAlreadyVerified: Bool = false,
         responseHandler: ResponseHandler = DefaultResponseHandler()) {
        self.phone = phone
        self.countryCode = countryCode
        self.phoneAlreadyVerified = phoneAlreadyVerified
        super.init(responseHandler: responseHandler)
    }

    @MainActor func loadCountries() async {
        guard countries.isEmpty else { return }
        do {
            let loadedCountries: [CountriesDataModel] = try await DefaultResponseHandler().data(
                from: CountriesEndpoints.list(), language: AppLanguageManager.shared.apiLanguage)
            try Task.checkCancellation()
            countries = loadedCountries
            let requestedCode = countryCode.trimmedPlus
            selectedCountry = countries.first(where: { $0.countryCode?.trimmedPlus == requestedCode })
                ?? countries.first(where: { $0.countryCode?.trimmedPlus == "966" })
                ?? countries.first
            if let selectedCountry, !phoneAlreadyVerified {
                countryCode = selectedCountry.countryCode ?? countryCode
            }
        } catch {
            guard !Task.isCancelled, !(error is CancellationError) else { return }
            emitError(error)
        }
    }

    @MainActor func submit() {
        guard !submitting else { return }
        nameError = ""; phoneError = ""; emailError = ""; termsError = ""
        passwordError = isPasswordValid ? "" : "auth.passwordRequirements".localized
        name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        email = email.trimmingCharacters(in: .whitespacesAndNewlines)
        phone = AccountValidation.phoneDigits(phone)
        if name.count > 50 { nameError = "api.nameTooLong".localized }
        do { _ = try AuthValidationService.validate(name: name) } catch { nameError = error.localizedDescription }
        do { _ = try AuthValidationService.validate(phone: phone) } catch { phoneError = error.localizedDescription }
        if email.count > 50 || !AuthInput.validEmail(email) { emailError = "auth.invalidEmail".localized }
        if !acceptTerms { termsError = "auth.acceptTermsError".localized }
        if !phoneAlreadyVerified {
            guard let selected = selectedCountry?.countryCode else { phoneError = "auth.selectCountry".localized; return }
            countryCode = selected
        }
        guard [nameError, phoneError, emailError, termsError, passwordError].allSatisfy(\.isEmpty) else { return }
        let model = UserRegisterModel(
            name: name,
            phone: phone,
            countryCode: countryCode,
            email: email,
            password: password,
            acceptTerms: acceptTerms)
        submitting = true
        Task {
            defer { submitting = false }
            do {
                let response: APIEnvelope<SignupData> = try await DefaultResponseHandler().send(
                    AuthEndpoints.signup(model: model), language: AppLanguageManager.shared.apiLanguage)
                guard response.key == "success" || response.key == "needActive" else {
                    throw APIError.invalidResponse
                }
                password = ""
                verificationRequested.send(model)
            } catch { emitError(error) }
        }
    }
}
