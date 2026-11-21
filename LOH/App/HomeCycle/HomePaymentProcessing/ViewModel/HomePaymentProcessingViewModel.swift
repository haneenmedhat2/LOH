import Combine
import Foundation

@MainActor
final class HomePaymentProcessingViewModel: ObservableObject {
    let order: HomeCheckoutOrder
    @Published private(set) var isSubmitting = false
    @Published private(set) var receipt: HomeCheckoutReceipt?
    @Published private(set) var error: String?
    @Published private(set) var outcomeUnknown = false
    private var didSubmit = false
    private let client: DefaultResponseHandler
    private let currentToken: @MainActor () -> String?

    init(
        order: HomeCheckoutOrder,
        client: DefaultResponseHandler = DefaultResponseHandler(),
        currentToken: @escaping @MainActor () -> String? = { UserDefaults.accessToken }
    ) {
        self.order = order
        self.client = client
        self.currentToken = currentToken
    }

    func submit(language: String) async {
        // A view reappearance must never create the same order again.
        guard !didSubmit else { return }
        guard !Task.isCancelled else { return }
        didSubmit = true
        guard let token = currentToken(), !token.isEmpty else {
            error = APIError.missingSession.localizedDescription
            return
        }
        isSubmitting = true
        defer { isSubmitting = false }
        do {
            guard !token.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                  order.offer.isRemote, let couponID = Int(order.offer.id), couponID > 0,
                  order.pricing.isValid else { throw APIError.invalidResponse }
            let response: APIEnvelope<HomeCreatedOrderData> = try await client.send(
                CheckoutEndpoints.createOrder(quantity: order.quantity, couponID: couponID,
                                                  paymentType: order.paymentType.rawValue, token: token),
                language: language)
            guard response.key == "success" else { throw APIError.invalidResponse }
            if let data = response.data, !data.offers.allSatisfy({ $0.coupon.id == couponID }) {
                throw APIError.invalidResponse
            }
            let result = HomeCreateOrderResult(message: response.msg, data: response.data)
            guard currentToken() == token else { return }
            // A confirmed server acknowledgement survives navigation-task cancellation.
            receipt = HomeCheckoutReceipt(order: order, result: result)
        } catch {
            guard currentToken() == token else { return }
            self.error = error.localizedDescription
            // A disconnected request may already have reached the server; never retry it automatically.
            if case APIError.server = error {
                outcomeUnknown = false
            } else if case APIError.missingSession = error {
                outcomeUnknown = false
            } else {
                outcomeUnknown = true
            }
        }
    }
}
