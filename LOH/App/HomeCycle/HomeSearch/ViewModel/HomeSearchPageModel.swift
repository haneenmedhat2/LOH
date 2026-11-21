import Foundation
import Combine

@MainActor
final class HomeSearchPageModel: ObservableObject {
    @Published private(set) var page: HomeSearchPageData?
    @Published private(set) var loading = false
    @Published private(set) var error: String?

    private let client: DefaultResponseHandler
    private var requestID = UUID()
    private var context = ""

    init(client: DefaultResponseHandler = DefaultResponseHandler()) {
        self.client = client
    }

    func load(language: String, token: String?) async {
        let nextContext = "\(language):\(token ?? "guest")"
        if context != nextContext {
            context = nextContext
            page = nil
        }
        let id = UUID()
        requestID = id
        loading = true
        error = nil
        defer { if requestID == id { loading = false } }
        do {
            let result: HomeSearchPageData = try await client.data(
                from: HomeEndpoints.searchPage(token: token), language: language)
            try Task.checkCancellation()
            guard requestID == id else { return }
            page = result
        } catch {
            if requestID == id && !Task.isCancelled {
                self.error = error.localizedDescription
            }
        }
    }

}
