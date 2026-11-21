import Foundation
import Combine

@MainActor
final class OnboardingViewModel: ObservableObject {
    @Published private(set) var pages: [OnboardingPage] = []
    @Published private(set) var isLoading = true
    @Published private(set) var errorMessage: String?
    @Published var selectedPage = 0
    private var loadID = UUID()

    var isLastPage: Bool { pages.isEmpty || selectedPage >= pages.count - 1 }

    func load(language: String) async {
        let id = UUID()
        loadID = id
        isLoading = true; errorMessage = nil; pages = []; selectedPage = 0
        defer { if loadID == id { isLoading = false } }
        do {
            let pages: [OnboardingPage] = try await DefaultResponseHandler().data(
                from: IntrosEndpoints.user(), language: language)
            guard Set(pages.map(\.id)).count == pages.count else { throw APIError.invalidResponse }
            try Task.checkCancellation()
            guard loadID == id else { return }
            self.pages = pages
        } catch {
            guard loadID == id else { return }
            if Task.isCancelled || error is CancellationError { return }
            errorMessage = error.localizedDescription
        }
    }

    @discardableResult
    func advance() -> Bool {
        guard !isLoading, errorMessage == nil else { return false }
        guard !isLastPage else { return true }
        selectedPage += 1
        return false
    }
}
