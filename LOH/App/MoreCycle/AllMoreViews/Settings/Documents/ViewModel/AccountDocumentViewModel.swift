import Foundation
import Combine

@MainActor
final class AccountDocumentViewModel: ObservableObject {
    @Published private(set) var content: AccountDocumentContent?
    @Published private(set) var error: String?
    @Published private(set) var loading = false
    private let client: DefaultResponseHandler
    private var generation = UUID()

    init(client: DefaultResponseHandler = DefaultResponseHandler()) { self.client = client }

    func load(endpoint: AccountDocumentEndpoint, language: String) async {
        let generation = UUID()
        self.generation = generation
        loading = true; error = nil; content = nil
        defer { if self.generation == generation { loading = false } }
        do {
            let result: AccountDocumentContent = try await client.data(
                from: AccountEndpoints.document(endpoint), language: language)
            try Task.checkCancellation()
            guard self.generation == generation else { return }
            content = result
        } catch {
            if self.generation == generation && !Task.isCancelled { self.error = error.localizedDescription }
        }
    }
}
