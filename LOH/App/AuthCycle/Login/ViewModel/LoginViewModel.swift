//
//  LoginViewModel.swift
//  NewSwiftUIBase
//
//  Created by Mohamed Hadwa on 22/07/2025.
//

import Foundation

class LoginViewModel: BaseViewModel {
    @Published var showLoading: Bool = false
    @Published private(set) var submitting = false
    @Published var showError: Bool = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    @Published var phoneError: String = ""
    @Published var phone: String = ""
    @Published var password = "" {
        didSet { passwordError = "" }
    }
    @Published var passwordError = ""
    @Published private(set) var countries =  [CountriesDataModel]()
    @Published var selectedCountry: CountriesDataModel? = nil
    @Published var forceValidatePhone = false
    
    @Published var isLoginSuccess = false
    @Published var authResponse: APIEnvelope<APIUser>?
    @Published var loginModel: UserRegisterModel? = nil
    
    var phoneHasError: Bool {
        !phoneError.isEmpty
    }
    
    
    override init(responseHandler: ResponseHandler = DefaultResponseHandler()) {
        super.init(responseHandler: responseHandler)
        bindBaseViewModel()
    }
    func liveValidatePhone(_ value: String) {
        phoneError = ""
        do {
            _ = try AuthValidationService.validate(phone: value)
        }
        catch let error as AuthValidationError {
            if case .emptyPhone = error { return }
            phoneError = error.localizedDescription
            
        }catch{
            emitError(error)
            
        }
    }    
    
    private func bindBaseViewModel() {
        isLoadingSubject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLoading in
                guard let self else {return}
                showLoading = isLoading
            }
            .store(in: &cancellables)
        $phone
            .receive(on: DispatchQueue.main)
            .sink { [weak self] value in
                guard let self else {return}
                liveValidatePhone(value)
            }
            .store(in: &cancellables)
        $successMessage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in
                guard  let self, let message else {return}
                emitSuccess(message)
            }
            .store(in: &cancellables)
        errorSubject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] error in
                guard let self else {return}
                errorMessage = error.localizedDescription
                showError = true
            }
            .store(in: &cancellables)
    }
    
    
}

//MARK: - Validation -

extension LoginViewModel {
    private func handleValidationError(_ error: AuthValidationError) {
        switch error {
        case .emptyPhone, .shortPhone, .longPhone, .invalidPhone:
            phoneError = error.localizedDescription
        default:
            emitError(error)
        }
    }
    
    @MainActor
    func validateLogin(model: UserRegisterModel)  {
        guard !submitting else { return }
        phoneError = ""
        passwordError = (6...100).contains(password.count) ? "" : "api.passwordLength".localized
        do {
            var model = model
            model.phone = AccountValidation.phoneDigits(model.phone ?? "")
            phone = model.phone ?? ""
            _ = try AuthValidationService.validate(phone: model.phone)
            guard let countryCode = model.countryCode, !countryCode.isEmpty else {
                phoneError = "auth.selectCountry".localized
                return
            }
            
            guard passwordError.isEmpty else { return }
            login(model: model)
        } catch let error as AuthValidationError {
            handleValidationError(error)
        } catch {
            emitError(error)
        }
    }
}

//MARK: - Networking -
@MainActor
extension LoginViewModel{
    private func login(model: UserRegisterModel) {
        guard let deviceID = FCMDeviceIdentity.current else {
            emitError(APIError.pushNotificationTokenUnavailable)
            return
        }
        showLoading = true
        submitting = true
        let submittedPassword = password
        Task {
            defer { showLoading = false; submitting = false }
            do {
                let response: APIEnvelope<APIUser> = try await DefaultResponseHandler().send(
                    AuthEndpoints.login(phone: AccountValidation.phoneDigits(model.phone ?? ""),
                        countryCode: (model.countryCode ?? "966").replacingOccurrences(of: "+", with: ""),
                        password: submittedPassword, deviceID: deviceID),
                    language: AppLanguageManager.shared.apiLanguage)
                password = ""
                authResponse = response
            } catch { emitError(error) }
        }
    }
    
    @MainActor
    func getCountries() async {
        guard countries.isEmpty else { return }
        do {
            let loadedCountries: [CountriesDataModel] = try await DefaultResponseHandler().data(
                from: CountriesEndpoints.list(), language: AppLanguageManager.shared.apiLanguage)
            try Task.checkCancellation()
            countries = loadedCountries
            selectedCountry = countries.first(where: { $0.countryCode?.trimmedPlus == "966" }) ?? countries.first
        } catch {
            guard !Task.isCancelled, !(error is CancellationError) else { return }
            emitError(error)
        }
    }
}
