import Foundation

@MainActor final class AuthSession {
    static let shared = AuthSession()
    var token: String?
}

private final class CheckoutURLProtocol: URLProtocol {
    static var handler: ((URLRequest) throws -> (Int, String))!
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        do {
            let (status, body) = try Self.handler(request)
            client?
                .urlProtocol(
                    self,
                    didReceive: HTTPURLResponse(
                        url: request.url!, statusCode: status, httpVersion: nil, headerFields: nil)!,
                    cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: Data(body.utf8))
            client?.urlProtocolDidFinishLoading(self)
        } catch { client?.urlProtocol(self, didFailWithError: error) }
    }
    override func stopLoading() {}
}

private actor ControlledCheckout: CheckoutServicing {
    var calls = 0
    var continuation: CheckedContinuation<HomeCreateOrderResult, Error>?
    func createOrder(_ order: HomeCheckoutOrder, token: String, language: String) async throws -> HomeCreateOrderResult
    {
        calls += 1
        return try await withCheckedThrowingContinuation { continuation = $0 }
    }
    func finish(_ result: Result<HomeCreateOrderResult, Error>) {
        continuation?.resume(with: result)
        continuation = nil
    }
}

@MainActor enum CheckoutServiceTests {
    static func run() async throws {
        var offer = HomeOffer(
            id: "197", merchant: "TestLoh", title: "Test Offer", category: .restaurants, asset: "", price: 10,
            originalPrice: 10, distance: 0, rating: 0, discount: 0, searchTerms: "")
        offer.isRemote = true
        offer.serviceFee = 1
        offer.totalPrice = 11
        offer.store = .init(id: 78, name: "TestLoh", image: nil, isVerified: true)
        let pricing = HomeCheckoutPricing(offer: offer, quantity: 2)
        precondition(pricing.subtotal == 20 && pricing.serviceFee == 2 && pricing.total == 22)
        precondition(!HomeCheckoutPricing(offer: offer, quantity: 0).isValid)
        precondition(!HomeCheckoutPricing(offer: offer, quantity: 11).isValid)
        let review = HomeOrderReviewViewModel(offer: offer)
        for _ in 0..<20 { review.increaseQuantity() }
        precondition(review.quantity == 10 && review.pricing.total == 110)
        for _ in 0..<20 { review.decreaseQuantity() }
        precondition(review.quantity == 1)

        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [CheckoutURLProtocol.self]
        let session = URLSession(configuration: config)
        defer { session.invalidateAndCancel() }
        let service = LOHCheckoutService(
            client: APIClient(baseURL: URL(string: "https://example.invalid/api/")!, session: session))
        let success = try String(
            contentsOfFile: "Tests/Checkout/Fixtures/create-new-order-success.json", encoding: .utf8)
        for method in HomeOrderPaymentType.allCases {
            CheckoutURLProtocol.handler = { request in
                precondition(request.url?.path == "/api/create-new-order" && request.httpMethod == "POST")
                precondition(request.value(forHTTPHeaderField: "Authorization") == "Bearer checkout-test")
                precondition(request.value(forHTTPHeaderField: "lang") == "ar")
                precondition(
                    request.value(forHTTPHeaderField: "Content-Type")?.hasPrefix("multipart/form-data;") == true)
                var data = request.httpBody ?? Data()
                if let stream = request.httpBodyStream {
                    stream.open()
                    defer { stream.close() }
                    var buffer = [UInt8](repeating: 0, count: 1024)
                    while true {
                        let count = stream.read(&buffer, maxLength: buffer.count)
                        if count <= 0 { break }
                        data.append(contentsOf: buffer.prefix(count))
                    }
                }
                let body = String(decoding: data, as: UTF8.self)
                precondition(body.components(separatedBy: "Content-Disposition:").count == 4)
                precondition(body.contains("name=\"amount\"\r\n\r\n2\r\n"))
                precondition(body.contains("name=\"coupon_id\"\r\n\r\n197\r\n"))
                precondition(body.contains("name=\"payment_type\"\r\n\r\n\(method.rawValue)\r\n"))
                precondition(!body.contains("pay_data") && !body.contains("card_id") && !body.contains("store_id"))
                return (200, success)
            }
            let order = HomeCheckoutOrder(offer: offer, quantity: 2, paymentType: method)
            let result = try await service.createOrder(order, token: "checkout-test", language: "ar")
            let receipt = HomeCheckoutReceipt(order: order, result: result)
            precondition(result.message == "تم الدفع بنجاح")
            precondition(receipt.total == 22 && !receipt.isPreview && receipt.code == nil && receipt.qrPayload == nil)
        }
        try await createdOffersTests(service: service, offer: offer)
        for (status, response) in [
            (400, #"{"key":"fail","msg":"Unavailable"}"#), (401, #"{"key":"unauthenticated"}"#), (500, "not JSON"),
            (200, #"{"key":"needActive"}"#)
        ] {
            CheckoutURLProtocol.handler = { _ in (status, response) }
            do {
                _ = try await service.createOrder(
                    .init(offer: offer, quantity: 1, paymentType: .visa), token: "test", language: "en")
                preconditionFailure("Must reject a failed or unconfirmed payment")
            } catch {}
        }
        CheckoutURLProtocol.handler = { _ in preconditionFailure("Invalid orders must never reach the server") }
        for quantity in [0, 11] {
            do {
                _ = try await service.createOrder(
                    .init(offer: offer, quantity: quantity, paymentType: .visa), token: "test", language: "en")
                preconditionFailure("Invalid quantity")
            } catch {}
        }
        do {
            _ = try await service.createOrder(
                .init(offer: offer, quantity: 1, paymentType: .visa), token: "", language: "en")
            preconditionFailure("No session")
        } catch {}
        offer.available = false
        do {
            _ = try await service.createOrder(
                .init(offer: offer, quantity: 1, paymentType: .visa), token: "test", language: "en")
            preconditionFailure("Unavailable offer")
        } catch {}
        offer.available = true
        try await selectionTests(offer)
        await submissionTests(offer)
        print(
            "PASS: checkout multipart fields, omitted pay_data, server success without data, fees, payment methods, failure handling, deduplication and session isolation"
        )
    }

    private static func createdOffersTests(service: LOHCheckoutService, offer: HomeOffer) async throws {
        let fixture = try Data(contentsOf: URL(fileURLWithPath: "Tests/Checkout/Fixtures/create-new-order-offers.json"))
        let order = HomeCheckoutOrder(offer: offer, quantity: 2, paymentType: .visa)
        CheckoutURLProtocol.handler = { _ in (200, String(decoding: fixture, as: UTF8.self)) }
        let result = try await service.createOrder(order, token: "checkout-test", language: "ar")
        let receipt = HomeCheckoutReceipt(order: order, result: result)
        precondition(result.data?.orderID == 528 && receipt.purchases.count == 1)
        let purchase = receipt.purchases[0]
        precondition(purchase.id == 916 && purchase.coupon.id == 197 && purchase.store?.id == 78)
        precondition(purchase.coupon.name == "Test Offer" && purchase.coupon.description == "New offer")
        precondition(purchase.coupon.image == "https://example.invalid/coupons/197.png")
        precondition(purchase.store?.name == "TestLoh" && purchase.store?.address?.contains("عرعر") == true)
        precondition(purchase.order?.id == 528 && purchase.order?.number == "#LOH-2026528")
        precondition(purchase.order?.paymentMethodText == "Visa / Mastercard")
        precondition(purchase.order?.currency == "ريال" && receipt.total == 2)
        precondition(purchase.purchasedAt == "27 أكتوبر 2026، 4:02 م")
        precondition(purchase.expiresAt == "26 ديسمبر 2026")
        precondition(purchase.header?.title == "عرضك جاهز للاستخدام" && purchase.howToUse?.steps.count == 3)
        precondition(purchase.rating?.canRate == false && purchase.rating?.isRated == false)
        precondition(purchase.code == "CHECKOUT-TEST-916" && purchase.canShowCode(status: nil))
        precondition(purchase.voucherCode?.qrURL?.absoluteString == "https://example.invalid/qr/CHECKOUT-TEST-916.png")
        precondition(!receipt.isPreview && receipt.code == nil && receipt.qrPayload == nil)
        precondition(Set([receipt, HomeCheckoutReceipt(order: order, result: result)]).count == 1)

        let json = try JSONSerialization.jsonObject(with: fixture) as! [String: Any]
        let data = json["data"] as! [String: Any]
        let first = (data["offers"] as! [[String: Any]])[0]
        var second = first
        second["id"] = 917
        var secondCode = first["code"] as! [String: Any]
        secondCode["coupon_number"] = "CHECKOUT-TEST-917"
        secondCode["qr"] = "https://example.invalid/qr/CHECKOUT-TEST-917.png"
        second["code"] = secondCode

        func response(offers: [[String: Any]], orderID: Int = 528) throws -> String {
            var copy = json
            copy["data"] = ["order_id": orderID, "offers": offers]
            return String(decoding: try JSONSerialization.data(withJSONObject: copy), as: UTF8.self)
        }

        let multiple = try response(offers: [first, second])
        CheckoutURLProtocol.handler = { _ in (200, multiple) }
        let multipleResult = try await service.createOrder(order, token: "checkout-test", language: "ar")
        let multipleReceipt = HomeCheckoutReceipt(order: order, result: multipleResult)
        precondition(multipleReceipt.purchases.map(\.id) == [916, 917])
        precondition(multipleReceipt.purchases.map(\.code) == ["CHECKOUT-TEST-916", "CHECKOUT-TEST-917"])
        precondition(multipleReceipt.total == 2, "Repeated order totals must never be added or multiplied")

        var inactive = first
        var inactiveCode = first["code"] as! [String: Any]
        inactiveCode["is_active"] = false
        inactive["code"] = inactiveCode
        var used = first
        used["status"] = "used"
        var ended = first
        ended["status"] = "ended"
        for unavailable in [inactive, used, ended] {
            let body = try response(offers: [unavailable])
            CheckoutURLProtocol.handler = { _ in (200, body) }
            let unavailableResult = try await service.createOrder(order, token: "checkout-test", language: "ar")
            precondition(unavailableResult.data?.offers[0].canShowCode(status: nil) == false)
        }

        var differentCoupon = first
        var coupon = first["coupon"] as! [String: Any]
        coupon["id"] = 999
        differentCoupon["coupon"] = coupon
        for body in [
            try response(offers: [first], orderID: 529),
            try response(offers: [first, first]),
            try response(offers: [differentCoupon]),
            try response(offers: [], orderID: 0)
        ] {
            CheckoutURLProtocol.handler = { _ in (200, body) }
            do {
                _ = try await service.createOrder(order, token: "checkout-test", language: "ar")
                preconditionFailure("Mismatched or duplicated vouchers must not be attached to a payment")
            } catch {}
        }

        let empty = try response(offers: [])
        CheckoutURLProtocol.handler = { _ in (200, empty) }
        let emptyResult = try await service.createOrder(order, token: "checkout-test", language: "ar")
        precondition(emptyResult.data?.orderID == 528 && emptyResult.data?.offers.isEmpty == true)

        let controlled = ControlledCheckout()
        let model = HomePaymentProcessingViewModel(order: order, service: controlled, currentToken: { "checkout-test" })
        let task = Task { await model.submit(language: "ar") }
        while await controlled.calls == 0 { await Task.yield() }
        await controlled.finish(.success(result))
        await task.value
        precondition(model.receipt?.purchases.first?.id == 916 && model.receipt?.total == 2)
        print(
            "PASS: created order 528/voucher 916 response, server receipt fields, active codes, multiple vouchers and mismatched IDs"
        )
    }

    private static func selectionTests(_ offer: HomeOffer) async throws {
        let model = HomePaymentViewModel(offer: offer, quantity: 2)
        precondition(model.makeOrder()?.paymentType == .applepay)
        precondition(model.makeOrder() == nil)
        model.resumeSelection()
        model.select(.card)
        precondition(model.selectedCardID == nil && model.makeOrder()?.paymentType == .visa)
        model.resumeSelection()
        let card = try JSONDecoder()
            .decode(
                AccountCard.self,
                from: Data(
                    #"{"id":7,"brand":"mastercard","last_four":"8888","is_default":false,"expiry":"12/28"}"#.utf8))
        model.selectCard(card)
        precondition(model.selectedCardID == 7 && model.makeOrder()?.paymentType == .master)
        model.resumeSelection()
        model.selectCard(card)
        precondition(model.selectedCardID == nil && model.makeOrder()?.paymentType == .visa)
        model.resumeSelection()
        model.selectCard(card)
        model.select(.card)
        precondition(model.selectedCardID == nil && model.makeOrder()?.paymentType == .visa)
        model.resumeSelection()
        model.select(.cashback)
        precondition(model.makeOrder()?.paymentType == .cashback)
        precondition(HomeOrderPaymentType.cardBrand("unknown") == nil)
    }

    private static func submissionTests(_ offer: HomeOffer) async {
        let order = HomeCheckoutOrder(offer: offer, quantity: 2, paymentType: .visa)
        let service = ControlledCheckout()
        let model = HomePaymentProcessingViewModel(order: order, service: service, currentToken: { "test" })
        let task = Task { await model.submit(language: "ar") }
        while await service.calls == 0 { await Task.yield() }
        await model.submit(language: "ar")
        precondition(model.isSubmitting && model.receipt == nil)
        let count = await service.calls
        precondition(count == 1)
        await service.finish(.success(.init(message: "Paid")))
        await task.value
        precondition(model.receipt?.total == 22 && model.error == nil && !model.isSubmitting)
        await model.submit(language: "en")
        let finalCount = await service.calls
        precondition(finalCount == 1)

        let failure = ControlledCheckout()
        let failed = HomePaymentProcessingViewModel(order: order, service: failure, currentToken: { "test" })
        let failureTask = Task { await failed.submit(language: "en") }
        while await failure.calls == 0 { await Task.yield() }
        await failure.finish(.failure(URLError(.timedOut)))
        await failureTask.value
        precondition(failed.receipt == nil && failed.error != nil && failed.outcomeUnknown)
        await failed.submit(language: "en")
        let failureCount = await failure.calls
        precondition(failureCount == 1)

        var token = "old"
        let staleService = ControlledCheckout()
        let stale = HomePaymentProcessingViewModel(order: order, service: staleService, currentToken: { token })
        let staleTask = Task { await stale.submit(language: "en") }
        while await staleService.calls == 0 { await Task.yield() }
        token = "new"
        await staleService.finish(.success(.init(message: "Paid")))
        await staleTask.value
        precondition(stale.receipt == nil && stale.error == nil)

        let guestService = ControlledCheckout()
        let guest = HomePaymentProcessingViewModel(order: order, service: guestService, currentToken: { nil })
        await guest.submit(language: "en")
        let guestCount = await guestService.calls
        precondition(guest.error != nil && guestCount == 0)
    }
}
