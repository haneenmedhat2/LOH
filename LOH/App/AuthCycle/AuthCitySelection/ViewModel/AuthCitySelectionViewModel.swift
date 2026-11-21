import Foundation
import Combine

@MainActor
final class AuthCitySelectionViewModel: ObservableObject {
    @Published private(set) var options: [AuthOption] = []
    @Published var selected: Int?
    @Published var query = ""
    @Published private(set) var loading = false
    @Published private(set) var submitting = false
    @Published private(set) var error: String?

    private let responseHandler: DefaultResponseHandler

    init(responseHandler: DefaultResponseHandler = DefaultResponseHandler()) {
        self.responseHandler = responseHandler
    }

    var filteredOptions: [AuthOption] {
        let search = query.trimmingCharacters(in: .whitespacesAndNewlines)
        return options.filter { search.isEmpty || $0.name.localizedStandardContains(search) }
    }

    func load() async {
        guard !loading, let token = UserDefaults.accessToken else {
            return
        }
        loading = true
        error = nil
        defer { loading = false }

        do {
            options = try await responseHandler.data(
                from: AuthEndpoints.options(cities: true, token: token),
                language: AppLanguageManager.shared.apiLanguage)
            selected = options.first(where: { $0.isSelected })?.id
            if options.isEmpty {
                error = "api.noOptions".localized
            }
        } catch is CancellationError {
        } catch {
            self.error = error.localizedDescription
        }
    }

    func submit() async -> Bool {
        guard !submitting, let selected else {
            return false
        }
        submitting = true
        error = nil
        defer { submitting = false }

        do {
            guard let token = UserDefaults.accessToken else {
                throw APIError.missingSession
            }
            try await responseHandler.perform(
                AuthEndpoints.selectCity(id: selected, token: token),
                language: AppLanguageManager.shared.apiLanguage)
            return true
        } catch is CancellationError {
            return false
        } catch {
            self.error = error.localizedDescription
            return false
        }
    }
}
