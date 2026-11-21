import Foundation
import Combine

@MainActor
final class PurchaseRatingViewModel: ObservableObject {
    static let commentLimit = 250

    @Published var value: Int
    @Published var comment = "" {
        didSet {
            if comment.count > Self.commentLimit {
                comment = String(comment.prefix(Self.commentLimit))
            }
        }
    }
    @Published private(set) var tags: [PurchaseRatingTag] = []
    @Published private(set) var selectedTagIDs: Set<Int> = []
    @Published private(set) var loadingTags = false
    @Published private(set) var tagsError: String?
    private let client: DefaultResponseHandler
    private var requestID = UUID()

    var canSubmit: Bool { (1...5).contains(value) }

    init(initialRating: Int = 0, client: DefaultResponseHandler = DefaultResponseHandler()) {
        value = (1...5).contains(initialRating) ? initialRating : 0
        self.client = client
    }

    func loadTags(language: String) async {
        let request = UUID()
        requestID = request
        tagsError = nil
        loadingTags = true
        defer { if requestID == request { loadingTags = false } }
        do {
            let tags: [PurchaseRatingTag] = try await client.data(
                from: PurchaseEndpoints.ratingTags(), language: language)
            guard tags.allSatisfy({ $0.id > 0 && !$0.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }),
                  Set(tags.map(\.id)).count == tags.count else { throw APIError.invalidResponse }
            try Task.checkCancellation()
            guard requestID == request else { return }
            self.tags = tags
            selectedTagIDs.formIntersection(tags.map(\.id))
        } catch {
            if requestID == request, !Task.isCancelled {
                tagsError = error.localizedDescription
            }
        }
    }

    func toggleTag(_ id: Int) {
        guard tags.contains(where: { $0.id == id }) else { return }
        if selectedTagIDs.contains(id) {
            selectedTagIDs.remove(id)
        } else {
            selectedTagIDs.insert(id)
        }
    }
}
