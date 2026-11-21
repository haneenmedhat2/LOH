import Foundation
import Combine

@MainActor
final class PurchaseDetailViewModel: ObservableObject {
    let id: Int
    let fallbackStatus: PurchaseStatus?
    @Published private var loadedPurchase: PurchaseDetail?
    @Published private(set) var loading = false
    @Published private(set) var error: String?
    @Published private(set) var isSubmittingRating = false
    @Published private(set) var ratingError: String?
    @Published private var submittedRating: PurchaseDetail.Rating?
    private let client: DefaultResponseHandler
    private var requestID = UUID()
    private var loadedToken: String?
    var purchase: PurchaseDetail? { loadedToken == UserDefaults.accessToken ? loadedPurchase : nil }
    var status: PurchaseStatus? { purchase?.status ?? fallbackStatus }
    var canShowCode: Bool { purchase?.canShowCode(status: fallbackStatus) == true }
    var rating: PurchaseDetail.Rating? { purchase == nil ? nil : (submittedRating ?? purchase?.rating) }
    var canRate: Bool {
        status == .used && rating?.canRate == true && rating?.isRated == false && (purchase?.store?.id ?? 0) > 0
    }
    var codeIsInactive: Bool {
        purchase?.voucherCode?.isActive == false || status == .used || status == .expired
    }
    var codeStatusText: String? {
        guard let text = purchase?.voucherCode?.statusText,
            !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else { return nil }
        return text
    }

    init(
        id: Int, status: PurchaseStatus? = nil, client: DefaultResponseHandler = DefaultResponseHandler()
    ) {
        self.id = id
        fallbackStatus = status
        self.client = client
    }

    func load(language: String) async {
        let request = UUID()
        requestID = request
        loadedPurchase = nil
        submittedRating = nil
        ratingError = nil
        isSubmittingRating = false
        error = nil
        loading = false
        guard !Task.isCancelled else { return }
        guard let token = UserDefaults.accessToken else {
            error = APIError.missingSession.localizedDescription
            return
        }
        loadedToken = token
        loading = true
        defer { if requestID == request { loading = false } }
        do {
            guard id > 0, !token.isEmpty else { throw APIError.invalidResponse }
            let data: PurchaseDetailData = try await client.data(
                from: PurchaseEndpoints.details(id: id, token: token), language: language)
            guard let purchase = data.purchases.first(where: { $0.id == id }) else {
                throw APIError.invalidResponse
            }
            try Task.checkCancellation()
            guard requestID == request, UserDefaults.accessToken == token else { return }
            guard purchase.id == id else { throw APIError.invalidResponse }
            loadedPurchase = purchase
        } catch {
            if requestID == request, UserDefaults.accessToken == token, !Task.isCancelled {
                self.error = error.localizedDescription
            }
        }
    }

    func clearRatingError() {
        ratingError = nil
    }

    @discardableResult
    func submitRating(value: Int, comment: String, tagIDs: [Int] = [], language: String) async -> Bool {
        guard !isSubmittingRating, canRate, (1...5).contains(value),
            let storeID = purchase?.store?.id, let token = UserDefaults.accessToken
        else { return false }
        let request = requestID
        let comment = comment.trimmingCharacters(in: .whitespacesAndNewlines)
        isSubmittingRating = true
        ratingError = nil
        defer { if requestID == request { isSubmittingRating = false } }
        do {
            guard storeID > 0, (1...5).contains(value), tagIDs.allSatisfy({ $0 > 0 }), !token.isEmpty else {
                throw APIError.invalidResponse
            }
            var fields = [("rating", String(value))]
            if !comment.isEmpty { fields.append(("comment", comment)) }
            fields += Set(tagIDs).sorted().map { ("tags[]", String($0)) }
            try await client.perform(
                PurchaseEndpoints.rateStore(id: storeID, fields: fields, token: token), language: language)
            try Task.checkCancellation()
            guard requestID == request, UserDefaults.accessToken == token else { return false }
            submittedRating = PurchaseDetail.Rating(
                canRate: false, isRated: true, rating: Double(value),
                comment: comment.isEmpty ? nil : comment, label: nil
            )
            return true
        } catch {
            if requestID == request, UserDefaults.accessToken == token, !Task.isCancelled {
                ratingError = error.localizedDescription
            }
            return false
        }
    }
}
