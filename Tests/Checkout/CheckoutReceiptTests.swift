import Foundation

@main
struct CheckoutReceiptTests {
    static func main() async throws {
        let id = UUID(uuidString: "A1B23C4D-0000-4000-8000-000000000001")!
        let receipt = HomeCheckoutReceipt(offer: HomeOffer.samples[0], quantity: 3, method: "mada", id: id)
        precondition(receipt.total == 24)
        precondition(receipt.quantity == 3 && receipt.method == "mada")
        precondition(receipt.code == "DEMO-A1B23C4D")
        precondition(receipt.qrPayload == "LOH-DEMO-NOT-REDEEMABLE:" + receipt.code!)
        precondition(HomeCheckoutReceipt(offer: receipt.offer, quantity: 0, method: "card").quantity == 1)
        precondition(HomeCheckoutReceipt(offer: receipt.offer, quantity: 11, method: "card").quantity == 10)
        precondition(HomeCheckoutReceipt(offer: receipt.offer, quantity: 1, method: "applePay").id != receipt.id)
        try await CheckoutServiceTests.run()
        print("PASS: checkout quantity bounds, totals, stable copy/QR identity and non-redeemable preview payload")
    }
}
