import Foundation
import Combine

protocol ResponseHandler {}
class BaseViewModel: ObservableObject {
    let isLoadingSubject = CurrentValueSubject<Bool, Never>(false)
    let errorSubject = PassthroughSubject<Error, Never>()
    let successSubject = PassthroughSubject<String, Never>()
    var cancellables = Set<AnyCancellable>()
    init(responseHandler: ResponseHandler = DefaultResponseHandler()) {}
    func emitError(_ error: Error) { errorSubject.send(error) }
    func emitSuccess(_ message: String) { successSubject.send(message) }
}
struct Endpoint<T> {}
struct APIEnvelope<T> { let key: String }
struct SignupData {}
struct APIUser {}
struct User {}
enum APIError: Error { case invalidResponse, pushNotificationTokenUnavailable }
struct CountriesDataModel { let countryCode: String? }
struct CountriesEndpoints { static func list() -> Endpoint<[CountriesDataModel]> { Endpoint() } }
struct AuthEndpoints {
    static func login(phone: String, countryCode: String, password: String, deviceID: String) -> Endpoint<APIEnvelope<APIUser>> { Endpoint() }
    static func signup(model: UserRegisterModel) -> Endpoint<APIEnvelope<SignupData>> { Endpoint() }
}
enum FCMDeviceIdentity { static let current: String? = "test" }
final class AppLanguageManager { static let shared = AppLanguageManager(); let apiLanguage = "en" }
extension String {
    var trimmedPlus: String { replacingOccurrences(of: "+", with: "") }
    var localized: String { self }
}
enum AuthValidationError: Error { case emptyPhone, shortPhone, longPhone }
enum AuthValidationService {
    static func validate(phone: String?) throws -> String { phone ?? "" }
    static func validate(name: String?) throws -> String { name ?? "" }
}
struct DefaultResponseHandler: ResponseHandler {
    @MainActor static var load: () async throws -> [CountriesDataModel] = { [] }
    func data<T>(from endpoint: Endpoint<T>, language: String) async throws -> T {
        try await Self.load() as! T
    }
    func send<T>(_ endpoint: Endpoint<APIEnvelope<T>>, language: String) async throws -> APIEnvelope<T> {
        throw APIError.invalidResponse
    }
}

@main struct AuthCancellationTests {
    @MainActor static func main() async {
        await checkLogin()
        await checkRegistration()
        print("PASS: cancelled country requests are silent and do not update either auth screen; failures remain visible and retries succeed")
    }

    @MainActor static func checkLogin() async {
        let model = LoginViewModel()
        var errors = 0
        let subscription = model.errorSubject.sink { _ in errors += 1 }
        var pending: CheckedContinuation<[CountriesDataModel], Error>?
        DefaultResponseHandler.load = { try await withCheckedThrowingContinuation { pending = $0 } }
        let task = Task { await model.getCountries() }
        while pending == nil { await Task.yield() }
        task.cancel()
        pending?.resume(throwing: NSError(domain: "Alamofire", code: 1))
        await task.value
        precondition(errors == 0 && model.countries.isEmpty && model.selectedCountry == nil)
        DefaultResponseHandler.load = { throw APIError.invalidResponse }
        await model.getCountries()
        precondition(errors == 1)
        DefaultResponseHandler.load = { [CountriesDataModel(countryCode: "+966")] }
        await model.getCountries()
        precondition(model.selectedCountry?.countryCode == "+966")
        withExtendedLifetime(subscription) {}
    }

    @MainActor static func checkRegistration() async {
        let model = CompleteRegisterDataViewModel()
        var errors = 0
        let subscription = model.errorSubject.sink { _ in errors += 1 }
        var pending: CheckedContinuation<[CountriesDataModel], Error>?
        DefaultResponseHandler.load = { try await withCheckedThrowingContinuation { pending = $0 } }
        let task = Task { await model.loadCountries() }
        while pending == nil { await Task.yield() }
        task.cancel()
        pending?.resume(returning: [CountriesDataModel(countryCode: "+966")])
        await task.value
        precondition(errors == 0 && model.countries.isEmpty && model.selectedCountry == nil)
        DefaultResponseHandler.load = { throw CancellationError() }
        await model.loadCountries()
        precondition(errors == 0)
        DefaultResponseHandler.load = { throw APIError.invalidResponse }
        await model.loadCountries()
        precondition(errors == 1)
        DefaultResponseHandler.load = { [CountriesDataModel(countryCode: "+966")] }
        await model.loadCountries()
        precondition(model.selectedCountry?.countryCode == "+966")
        withExtendedLifetime(subscription) {}
    }
}
