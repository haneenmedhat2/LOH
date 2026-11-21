import Foundation
import Combine

@MainActor
final class FAQListViewModel: ObservableObject {
    @Published private(set) var data: FAQListData?
    @Published private(set) var loading = false
    @Published private(set) var error: String?
    @Published var selectedCategoryID: Int?
    private let client: DefaultResponseHandler
    private var request = UUID()

    init(client: DefaultResponseHandler = DefaultResponseHandler()) {
        self.client = client
    }

    var questions: [FAQQuestion] {
        guard let questions = data?.questions else { return [] }
        guard let selectedCategoryID else { return questions }
        return questions.filter { $0.categoryID == selectedCategoryID }
    }

    func load(language: String) async {
        let request = UUID()
        self.request = request
        loading = true
        error = nil
        defer { if self.request == request { loading = false } }
        do {
            let result: FAQListData = try await client.data(from: FAQEndpoints.list(), language: language)
            guard self.request == request, !Task.isCancelled else { return }
            data = result
        } catch {
            guard self.request == request, !Task.isCancelled else { return }
            self.error = error.localizedDescription
        }
    }
}

@MainActor
final class FAQDetailViewModel: ObservableObject {
    @Published private(set) var question: FAQQuestion?
    @Published private(set) var loading = false
    @Published private(set) var error: String?
    private let client: DefaultResponseHandler
    private var request = UUID()

    init(client: DefaultResponseHandler = DefaultResponseHandler()) {
        self.client = client
    }

    func load(id: Int, language: String) async {
        let request = UUID()
        self.request = request
        loading = true
        error = nil
        defer { if self.request == request { loading = false } }
        do {
            let result: FAQQuestion = try await client.data(from: try FAQEndpoints.detail(id: id), language: language)
            guard self.request == request, !Task.isCancelled else { return }
            question = result
        } catch {
            guard self.request == request, !Task.isCancelled else { return }
            self.error = error.localizedDescription
        }
    }
}
