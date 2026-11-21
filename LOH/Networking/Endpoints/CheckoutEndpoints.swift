import Foundation

struct CheckoutEndpoints {
    private init() {}
}

extension CheckoutEndpoints {
    static
    func createOrder(quantity: Int, couponID: Int, paymentType: String, token: String) -> Endpoint<APIEnvelope<HomeCreatedOrderData>> {
        return Endpoint(
            method: .post,
            path: "create-new-order",
            body: ["amount": quantity, "coupon_id": couponID, "payment_type": paymentType],
            headerType: .authorized(token: token)
        )
    }
}
