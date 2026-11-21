import Foundation
import Combine

@MainActor
final class AccountRequestController: ObservableObject {
    @Published private(set) var busy = false
    @Published var error: String?
    private var generation = UUID()
    var sessionScope: UUID { generation }
    func currentToken() -> String? { UserDefaults.accessToken }
    let client: DefaultResponseHandler
    var language: String { AppLanguageManager.currentLanguage() }

    init(client: DefaultResponseHandler = DefaultResponseHandler()) {
        self.client = client
    }

    @discardableResult
    func run(_ operation: (String, UUID) async throws -> Void) async -> Bool {
        guard !busy else { return false }
        guard let token = UserDefaults.accessToken else { error = APIError.missingSession.localizedDescription; return false }
        let generation = generation
        busy = true; error = nil
        defer { if self.generation == generation { busy = false } }
        do {
            try await operation(token, generation)
            try check(token, generation)
            return true
        } catch {
            if self.generation == generation && UserDefaults.accessToken == token && !Task.isCancelled {
                self.error = error.localizedDescription
            }
            return false
        }
    }
    func check(_ token: String, _ generation: UUID) throws {
        try Task.checkCancellation()
        guard self.generation == generation, UserDefaults.accessToken == token else { throw CancellationError() }
    }
    func resetSession() {
        generation = UUID()
        busy = false
        error = nil
    }
}
