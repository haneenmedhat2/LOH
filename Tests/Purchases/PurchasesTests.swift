import Foundation
import CoreImage

@MainActor final class AuthSession {
    static let shared = AuthSession()
    var token: String?
    init(token: String? = nil) { self.token = token }
}

final class PurchaseMockProtocol: URLProtocol {
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
                        url: request.url!, statusCode: status,
                        httpVersion: nil, headerFields: ["Content-Type": "application/json"])!,
                    cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: Data(body.utf8))
            client?.urlProtocolDidFinishLoading(self)
        } catch { client?.urlProtocol(self, didFailWithError: error) }
    }
    override func stopLoading() {}
}

@MainActor final class PurchaseFakeService: PurchaseServicing {
    var list: ((PurchaseStatus?, Int) async throws -> PurchasePage)!
    var detail: ((Int) async throws -> PurchaseDetail)!
    var rateAction: ((Int, Int, String, [Int]) async throws -> Void)!
    var tagsAction: ((String) async throws -> [PurchaseRatingTag])!
    func coupons(status: PurchaseStatus?, page: Int, token: String, language: String) async throws -> PurchasePage {
        try await list(status, page)
    }
    func details(id: Int, token: String, language: String) async throws -> PurchaseDetail { try await detail(id) }
    func rateStore(storeID: Int, rating: Int, comment: String, tagIDs: [Int], token: String, language: String) async throws {
        try await rateAction(storeID, rating, comment, tagIDs)
    }
    func ratingTags(language: String) async throws -> [PurchaseRatingTag] {
        try await tagsAction(language)
    }
}

@main struct PurchasesTests {
    static let coupon =
        #"{"id":4,"name":"Offer","store_name":"Store","code":"0046","price":"9,000.0","currency":"SAR"}"#
    static func page(_ page: Int = 1, pages: Int = 1, coupons: String = coupon) throws -> PurchasePage {
        try JSONDecoder()
            .decode(
                PurchasePage.self,
                from: Data(
                    """
                    {"pagination":{"total_items":3,"current_page":\(page),"total_pages":\(pages)},"coupons":[\(coupons)]}
                    """
                    .utf8))
    }
    static func envelope(_ data: String) -> String { "{\"key\":\"success\",\"data\":\(data)}" }

    @MainActor static func main() async throws {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [PurchaseMockProtocol.self]
        let transport = URLSession(configuration: config)
        defer { transport.invalidateAndCancel() }
        let service = LOHPurchaseService(
            client: APIClient(baseURL: URL(string: "https://example.invalid/api/")!, session: transport))
        for comment in ["", "  Great visit  "] {
            PurchaseMockProtocol.handler = { request in
                precondition(request.httpMethod == "POST" && request.url!.path == "/api/rate-store/78")
                precondition(request.value(forHTTPHeaderField: "Authorization") == "Bearer test-session")
                precondition(request.value(forHTTPHeaderField: "lang") == "ar")
                let body = Self.requestBody(request)
                precondition(body.contains("name=\"rating\"\r\n\r\n4\r\n"))
                precondition(!body.contains("name=\"tags[]\""), "Do not invent optional rating tags")
                if comment.isEmpty {
                    precondition(!body.contains("name=\"comment\""))
                } else {
                    precondition(body.contains("name=\"comment\"\r\n\r\nGreat visit\r\n"))
                }
                return (200, #"{"key":"success","msg":"Rated"}"#)
            }
            try await service.rateStore(storeID: 78, rating: 4, comment: comment, token: "test-session", language: "ar")
        }
        PurchaseMockProtocol.handler = { _ in
            preconditionFailure("Invalid ratings must not reach the server")
        }
        for invalid in [0, 6] {
            do {
                try await service.rateStore(storeID: 78, rating: invalid, comment: "", token: "test-session", language: "ar")
                preconditionFailure("Invalid rating accepted")
            } catch {}
        }
        PurchaseMockProtocol.handler = { _ in (422, #"{"key":"fail","msg":"Already rated"}"#) }
        do {
            try await service.rateStore(storeID: 78, rating: 4, comment: "", token: "test-session", language: "ar")
            preconditionFailure("Rating rejection must be shown")
        } catch {
            precondition(error.localizedDescription == "Already rated")
        }
        print("PASS: rating multipart request, auth/language, optional comment, valid stars and server errors")
        let tagsFixture = try String(
            contentsOf: URL(fileURLWithPath: #filePath).deletingLastPathComponent().appendingPathComponent("Fixtures/rating-tags.json"),
            encoding: .utf8
        )
        PurchaseMockProtocol.handler = { request in
            precondition(request.httpMethod == "GET" && request.url!.path == "/api/rating-tags")
            precondition(request.value(forHTTPHeaderField: "lang") == "ar")
            precondition(request.value(forHTTPHeaderField: "Authorization") == nil)
            return (200, tagsFixture)
        }
        let ratingTags = try await service.ratingTags(language: "ar")
        precondition(ratingTags.map(\.id) == [1, 2, 3])
        precondition(ratingTags.map(\.name) == ["خدمة سريعة", "جودة ممتازة", "العرض مطابق"])
        PurchaseMockProtocol.handler = { request in
            let body = Self.requestBody(request)
            precondition(request.url!.path == "/api/rate-store/78")
            precondition(body.components(separatedBy: "name=\"tags[]\"").count == 3)
            precondition(body.contains("name=\"tags[]\"\r\n\r\n1\r\n"))
            precondition(body.contains("name=\"tags[]\"\r\n\r\n3\r\n"))
            return (200, #"{"key":"success"}"#)
        }
        try await service.rateStore(storeID: 78, rating: 4, comment: "", tagIDs: [3, 1, 3], token: "test-session", language: "ar")
        PurchaseMockProtocol.handler = { _ in (200, #"{"key":"success","data":[{"id":1,"name":"One"},{"id":1,"name":"Duplicate"}]}"#) }
        do {
            _ = try await service.ratingTags(language: "ar")
            preconditionFailure("Duplicate tag IDs must not reach the view")
        } catch {}
        print("PASS: live rating-tags fixture and deduplicated repeated tags[] multipart fields")
        let fixtureURL = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
            .appendingPathComponent("Fixtures/user-coupons.json")
        let fixture = try String(contentsOf: fixtureURL, encoding: .utf8)

        let currentFixture = try String(
            contentsOf: fixtureURL.deletingLastPathComponent().appendingPathComponent("user-coupons-current.json"),
            encoding: .utf8
        )
        PurchaseMockProtocol.handler = { request in
            precondition(request.url!.path == "/api/user-coupons" && request.url!.query == "page=1")
            return (200, currentFixture)
        }
        let currentPage = try await service.coupons(status: nil, page: 1, token: "test-session", language: "ar")
        precondition(currentPage.coupons.map(\.id) == [910, 909])
        precondition(currentPage.counts?.totals == [.all: 2, .ready: 1, .used: 1, .ended: 0])
        precondition(currentPage.pagination?.totalItems == 2 && currentPage.pagination?.totalPages == 1)
        let readyCoupon = currentPage.coupons[0]
        precondition(readyCoupon.couponID == 197 && readyCoupon.storeID == 78 && readyCoupon.availableCount == 2)
        precondition(readyCoupon.location == "الرياض" && readyCoupon.statusText == "جاهز للاستخدام")
        precondition(readyCoupon.couponNumber == "2010105800000910" && readyCoupon.reference == nil)
        precondition(readyCoupon.qrURL?.lastPathComponent == "2010105800000910.png")
        precondition(readyCoupon.code == nil && readyCoupon.canOpenCode(status: nil))
        precondition(readyCoupon.rating?.isRated == false && readyCoupon.rating?.displayValue == nil)
        let usedCoupon = currentPage.coupons[1]
        precondition(usedCoupon.status == .used && usedCoupon.availableCount == 0 && !usedCoupon.canOpenCode(status: .ready))
        let ratedRow = try JSONDecoder().decode(PurchaseCoupon.self, from: Data(
            #"{"id":909,"name":"Offer","is_rated":true,"rating":4.5,"coupon_number":"000123","store_address":"Riyadh"}"#.utf8))
        precondition(ratedRow.rating?.displayValue == 4.5 && ratedRow.couponNumber == "000123")
        precondition(ratedRow.location == "Riyadh")
        let unratedRow = try JSONDecoder().decode(PurchaseCoupon.self, from: Data(
            #"{"id":909,"name":"Offer","is_rated":false,"rating":4}"#.utf8))
        precondition(unratedRow.rating?.displayValue == nil)
        let nullRatingRow = try JSONDecoder().decode(PurchaseCoupon.self, from: Data(
            #"{"id":909,"name":"Offer","is_rated":false,"rating":null,"qr":"javascript:alert(1)"}"#.utf8))
        precondition(nullRatingRow.rating == nil && nullRatingRow.qrURL == nil)
        print("PASS: current user-coupons response, numeric ratings, store address, voucher IDs/numbers, QR URL and tab counts")

        for status in [nil, PurchaseStatus.ready, .used, .expired] {
            PurchaseMockProtocol.handler = { request in
                precondition(request.httpMethod == "GET" && request.url!.path == "/api/user-coupons")
                precondition(
                    request.httpBody == nil
                        && request.value(forHTTPHeaderField: "Authorization") == "Bearer test-session")
                precondition(request.value(forHTTPHeaderField: "lang") == "ar")
                let query = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)!.queryItems!
                precondition(query.contains(.init(name: "page", value: "1")))
                let expected = status == .expired ? "ended" : status?.rawValue
                precondition(query.first { $0.name == "status" }?.value == expected)
                return (200, fixture)
            }
            let page = try await service.coupons(status: status, page: 1, token: "test-session", language: "ar")
            precondition(page.coupons.count == 3 && page.coupons.allSatisfy { $0.id == 4 })
            precondition(page.coupons[0].price == 9000 && page.coupons[0].location == "الرياض")
            precondition(page.coupons[0].status == nil && page.coupons[0].purchasedAt == nil)
        }
        for data in [coupon, "{\"coupon\":\(coupon)}", "{\"coupons\":[\(coupon),\(coupon)]}"] {
            PurchaseMockProtocol.handler = { request in
                precondition(request.url!.path == "/api/user-coupon-details/4" && request.httpMethod == "GET")
                precondition(request.url!.query == nil && request.httpBody == nil)
                return (200, envelope(data))
            }
            let detail = try await service.details(id: 4, token: "test-session", language: "en")
            precondition(detail.code == "0046" && detail.order?.paidAmount == 9000)
            precondition(detail.canShowCode(status: .ready))
            precondition(!detail.canShowCode(status: .expired) && !detail.canShowCode(status: .used))
        }
        let detailFixtureURL = fixtureURL.deletingLastPathComponent()
            .appendingPathComponent("user-coupon-details-910.json")
        let detailFixture = try String(contentsOf: detailFixtureURL, encoding: .utf8)
        let nestedData = try JSONSerialization.jsonObject(with: Data(detailFixture.utf8)) as! [String: Any]
        let nestedRowData = try JSONSerialization.data(withJSONObject: nestedData["data"]!)
        let nestedRow = try JSONDecoder().decode(PurchaseCoupon.self, from: nestedRowData)
        precondition(nestedRow.id == 910 && nestedRow.name == "Test Offer" && nestedRow.merchant == "TestLoh")
        precondition(nestedRow.statusText == "جاهز للاستخدام" && nestedRow.location == "الرياض")
        precondition(nestedRow.reference == "#LOH-2026524" && nestedRow.storeImage != nil)
        precondition(nestedRow.canOpenCode(status: nil) && !nestedRow.canShowCode(status: nil))
        precondition(nestedRow.rating?.displayValue == nil, "Unrated zero is not a submitted rating")
        let readyWithoutCode = try JSONDecoder().decode(
            PurchaseCoupon.self, from: Data(#"{"id":910,"name":"Offer","status":"ready","status_text":"Ready"}"#.utf8))
        precondition(readyWithoutCode.canOpenCode(status: nil), "A ready row opens details to retrieve its code")
        precondition(!readyWithoutCode.canShowCode(status: nil))
        for status in ["used", "ended"] {
            let row = try JSONDecoder().decode(PurchaseCoupon.self, from: Data(
                "{\"id\":911,\"name\":\"Offer\",\"status\":\"\(status)\",\"rating\":{\"is_rated\":true,\"can_rate\":false,\"rating\":4,\"rating_label\":\"Rated\"}}".utf8))
            precondition(!row.canOpenCode(status: .ready))
            precondition(row.rating?.displayValue == 4 && row.rating?.label == "Rated")
        }
        for sampleCode in ["000123", "A1B2 3C4D", " TEST-ONLY-0046 "] {
            let payload = detailFixture.replacingOccurrences(of: "[REDACTED]", with: sampleCode)
            let envelope = try JSONDecoder().decode(APIEnvelope<PurchaseDetail>.self, from: Data(payload.utf8))
            let purchase = envelope.data!
            let qr = PurchaseQRCode.image(for: purchase, fallbackStatus: nil)!
            let detector = CIDetector(ofType: CIDetectorTypeQRCode, context: CIContext(), options: [CIDetectorAccuracy: CIDetectorAccuracyHigh])!
            let messages = detector.features(in: CIImage(cgImage: qr)).compactMap { ($0 as? CIQRCodeFeature)?.messageString }
            precondition(messages == [sampleCode], "QR must round-trip the exact server code, including zeros and spaces")
            let query = URLComponents(url: purchase.storeSearchURL!, resolvingAgainstBaseURL: false)!.queryItems!
            precondition(query.first?.value == "TestLoh, الرياض")
        }
        let redacted = try JSONDecoder().decode(PurchaseDetail.self, from: nestedRowData)
        precondition(PurchaseQRCode.image(for: redacted, fallbackStatus: .ready) == nil)
        print("PASS: ready navigation without a list code, status/rating/location mapping, exact QR payload round-trip")
        var detailResponse = detailFixture
        PurchaseMockProtocol.handler = { request in
            precondition(request.url!.path == "/api/user-coupon-details/910")
            precondition(request.httpMethod == "GET" && request.httpBody == nil && request.url!.query == nil)
            precondition(request.value(forHTTPHeaderField: "Authorization") == "Bearer test-session")
            precondition(request.value(forHTTPHeaderField: "lang") == "ar")
            return (200, detailResponse)
        }
        let purchased = try await service.details(id: 910, token: "test-session", language: "ar")
        precondition(purchased.id == 910 && purchased.coupon.id == 197 && purchased.order?.id == 524)
        precondition(purchased.coupon.name == "Test Offer" && purchased.coupon.description == "New offer")
        precondition(
            purchased.store?.id == 78 && purchased.store?.name == "TestLoh" && purchased.store?.address == "الرياض")
        precondition(purchased.status == .ready && purchased.statusText == "جاهز للاستخدام")
        precondition(purchased.header?.title == "عرضك جاهز للاستخدام" && purchased.header?.dateText == nil)
        precondition(purchased.order?.number == "#LOH-2026524" && purchased.order?.paidAmount == 2)
        precondition(purchased.order?.currency == "ريال" && purchased.order?.paymentMethod == "visa")
        precondition(purchased.order?.paymentMethodText == "Visa / Mastercard")
        precondition(purchased.expiresAt == "25 ديسمبر 2026" && purchased.finishUsageAt == "2026-12-25 13:18:16")
        precondition(purchased.purchasedAt == "26 أكتوبر 2026، 1:18 م")
        precondition(purchased.howToUse?.steps.count == 3 && purchased.howToUse?.title == "كيف أستخدم العرض؟")
        precondition(
            purchased.rating?.canRate == false && purchased.rating?.isRated == false && purchased.rating?.comment == nil
        )
        precondition(!purchased.canShowCode(status: .ready), "Redacted examples are never redeemable codes")
        let objectFixture = try String(
            contentsOf: fixtureURL.deletingLastPathComponent().appendingPathComponent("user-coupon-details-910-code-object.json"),
            encoding: .utf8
        )
        // Reproduce the old String-only failure using the actual, unmasked shape.
        struct OldCodeDecoder: Decodable { let code: String }
        do {
            _ = try JSONDecoder().decode(APIEnvelope<OldCodeDecoder>.self, from: Data(objectFixture.utf8))
            preconditionFailure("The old String decoder must reject a code object")
        } catch {
            let diagnostic = APILogger.decodingFailure(error, response: Data(objectFixture.utf8))
            precondition(diagnostic == "data.code: expected String, received object")
            precondition(!diagnostic.contains("TEST-ONLY") && !diagnostic.contains("example.invalid"))
        }
        detailResponse = objectFixture
        let activeCode = try await service.details(id: 910, token: "test-session", language: "ar")
        precondition(activeCode.code == "TEST-ONLY-0910" && activeCode.voucherCode?.isActive == true)
        precondition(activeCode.voucherCode?.qrURL?.absoluteString == "https://example.invalid/vouchers/TEST-ONLY-0910.png")
        precondition(activeCode.voucherCode?.statusText == nil && activeCode.canShowCode(status: .ready))
        precondition(PurchaseQRCode.image(for: activeCode, fallbackStatus: .ready) != nil)
        let codeSession = AuthSession(token: "code-test-session")
        let codeService = PurchaseFakeService()
        codeService.detail = { _ in activeCode }
        let codeModel = PurchaseDetailViewModel(id: 910, status: .ready, service: codeService, session: codeSession)
        await codeModel.load(language: "ar")
        precondition(codeModel.error == nil && codeModel.purchase?.coupon.name == "Test Offer" && codeModel.canShowCode)
        for status in ["ready", "used", "ended"] {
            detailResponse = objectFixture.replacingOccurrences(of: "\"is_active\": true", with: "\"is_active\": false")
                .replacingOccurrences(of: "\"status_text\": null", with: "\"status_text\": \"Code is inactive\"")
                .replacingOccurrences(of: "\"status\": \"ready\"", with: "\"status\": \"\(status)\"")
            let inactive = try await service.details(id: 910, token: "test-session", language: "ar")
            precondition(!inactive.canShowCode(status: .ready))
            precondition(PurchaseQRCode.image(for: inactive, fallbackStatus: .ready) == nil)
            codeService.detail = { _ in inactive }
            await codeModel.load(language: "ar")
            precondition(codeModel.error == nil && codeModel.codeIsInactive && !codeModel.canShowCode)
            precondition(codeModel.codeStatusText == "Code is inactive")
        }
        detailResponse = objectFixture.replacingOccurrences(of: "https://example.invalid/vouchers/TEST-ONLY-0910.png", with: "javascript:alert(1)")
        let invalidQR = try await service.details(id: 910, token: "test-session", language: "ar")
        precondition(invalidQR.voucherCode?.qrURL == nil && invalidQR.code == "TEST-ONLY-0910")
        precondition(PurchaseQRCode.image(for: invalidQR, fallbackStatus: .ready) != nil)
        print("PASS: structured code object loads both screen models; inactive codes blocked; safe field-level diagnostics")
        // The original masked console sample did not reveal whether the server
        // returned a string, number, or object. Keep scalar compatibility covered.
        detailResponse = detailFixture.replacingOccurrences(of: "\"[REDACTED]\"", with: "2010105800000910")
        let numericCodePurchase = try await service.details(id: 910, token: "test-session", language: "ar")
        precondition(numericCodePurchase.code == "2010105800000910")
        precondition(numericCodePurchase.canShowCode(status: .ready))
        detailResponse = detailFixture.replacingOccurrences(of: "[REDACTED]", with: "TEST-ONLY-0046")
        let withCode = try await service.details(id: 910, token: "test-session", language: "ar")
        precondition(withCode.code == "TEST-ONLY-0046" && withCode.canShowCode(status: nil))
        for state in ["used", "ended"] {
            detailResponse = detailFixture.replacingOccurrences(of: "[REDACTED]", with: "TEST-ONLY-0046")
                .replacingOccurrences(of: "\"status\": \"ready\"", with: "\"status\": \"\(state)\"")
            let unavailable = try await service.details(id: 910, token: "test-session", language: "ar")
            precondition(!unavailable.canShowCode(status: .ready))
        }
        detailResponse = detailFixture.replacingOccurrences(of: "\"id\": 910", with: "\"id\": 911")
        do {
            _ = try await service.details(id: 910, token: "test-session", language: "ar")
            preconditionFailure("A different purchased voucher must not be displayed")
        } catch {}
        PurchaseMockProtocol.handler = { _ in (200, detailFixture) }
        do {
            _ = try await service.details(id: 197, token: "test-session", language: "ar")
            preconditionFailure("The nested coupon ID must never match a purchase detail request")
        } catch {}
        print(
            "PASS: nested purchase 910 response, distinct coupon/order/store IDs, payment/date/header/usage/rating data, redacted and unavailable codes"
        )

        PurchaseMockProtocol.handler = { _ in (200, fixture) }
        do {
            _ = try await service.details(id: 3, token: "test-session", language: "en")
            preconditionFailure("Mismatched detail ID")
        } catch {}
        for data in ["null", "{}", "{\"coupons\":[{\"name\":\"Missing ID\"}]}"] {
            PurchaseMockProtocol.handler = { _ in (200, envelope(data)) }
            do {
                _ = try await service.coupons(status: nil, page: 1, token: "test-session", language: "en")
                preconditionFailure("Malformed response")
            } catch {}
        }
        PurchaseMockProtocol.handler = { _ in (200, envelope("{\"coupons\":[]}")) }
        let empty = try await service.coupons(status: nil, page: 1, token: "test-session", language: "en")
        precondition(empty.coupons.isEmpty)
        PurchaseMockProtocol.handler = { _ in (401, #"{"key":"unauthenticated","msg":"Expired"}"#) }
        do {
            _ = try await service.coupons(status: nil, page: 1, token: "test-session", language: "en")
            preconditionFailure("Unauthorized")
        } catch {}
        print(
            "PASS: collection fixture, list/detail requests, auth/language, ended filter, money, empty/malformed responses, mismatched detail IDs, server codes"
        )

        let session = AuthSession(token: "one")
        let fake = PurchaseFakeService()
        var ratingPayload = nestedData["data"] as! [String: Any]
        ratingPayload["status"] = "used"
        ratingPayload["rating"] = ["can_rate": true, "is_rated": false, "rating": 0]
        let rateable = try JSONDecoder().decode(
            PurchaseDetail.self, from: JSONSerialization.data(withJSONObject: ratingPayload))
        fake.detail = { _ in rateable }
        let ratingModel = PurchaseDetailViewModel(id: 910, status: .used, service: fake, session: session)
        await ratingModel.load(language: "ar")
        precondition(ratingModel.canRate && !ratingModel.canShowCode)
        fake.rateAction = { id, value, comment, tags in
            precondition(id == 78 && value == 4 && comment == "Great visit")
            precondition(tags == [1, 3])
            throw APIError.server("Please retry")
        }
        let failedRating = await ratingModel.submitRating(value: 4, comment: " Great visit ", tagIDs: [1, 3], language: "ar")
        precondition(!failedRating, "A failed rating must not show the success popup")
        precondition(ratingModel.ratingError == "Please retry" && ratingModel.canRate)
        var submitted = 0
        fake.rateAction = { _, _, _, _ in submitted += 1 }
        await ratingModel.submitRating(value: 0, comment: "", language: "ar")
        precondition(submitted == 0)
        let savedRating = await ratingModel.submitRating(value: 4, comment: " Great visit ", language: "ar")
        precondition(savedRating, "Only a confirmed rating may show the success popup")
        precondition(ratingModel.ratingError == nil && ratingModel.rating?.displayValue == 4)
        precondition(ratingModel.rating?.comment == "Great visit" && !ratingModel.canRate)
        await ratingModel.submitRating(value: 5, comment: "", language: "ar")
        precondition(submitted == 1, "A submitted rating cannot be submitted twice")

        await ratingModel.load(language: "ar")
        var ratingPending: CheckedContinuation<Void, Error>?
        fake.rateAction = { _, _, _, _ in
            try await withCheckedThrowingContinuation { ratingPending = $0 }
        }
        let ratingTask = Task {
            await ratingModel.submitRating(value: 5, comment: "", language: "ar")
        }
        while ratingPending == nil { await Task.yield() }
        precondition(ratingModel.isSubmittingRating)
        await ratingModel.submitRating(value: 4, comment: "", language: "ar")
        session.token = "different-session"
        ratingPending!.resume()
        let staleRating = await ratingTask.value
        precondition(!staleRating, "An old session must never show the success popup")
        precondition(ratingModel.rating == nil && ratingModel.purchase == nil && !ratingModel.isSubmittingRating)
        session.token = "one"
        print("PASS: rating confirmation/error, eligibility, duplicate submission prevention and session isolation")

        let ratingForm = PurchaseRatingViewModel(initialRating: 4, service: fake)
        precondition(ratingForm.value == 4 && ratingForm.canSubmit)
        ratingForm.comment = String(repeating: "🙂", count: 260)
        precondition(ratingForm.comment.count == 250)
        ratingForm.value = 0
        precondition(!ratingForm.canSubmit)
        fake.tagsAction = { _ in throw APIError.server("Tags unavailable") }
        await ratingForm.loadTags(language: "ar")
        precondition(ratingForm.tagsError == "Tags unavailable" && !ratingForm.loadingTags)
        fake.tagsAction = { _ in ratingTags }
        await ratingForm.loadTags(language: "ar")
        ratingForm.toggleTag(1)
        ratingForm.toggleTag(3)
        ratingForm.toggleTag(999)
        precondition(ratingForm.selectedTagIDs == [1, 3] && ratingForm.tagsError == nil)
        ratingForm.toggleTag(1)
        precondition(ratingForm.selectedTagIDs == [3])
        fake.tagsAction = { _ in Array(ratingTags.prefix(2)) }
        await ratingForm.loadTags(language: "en")
        precondition(ratingForm.selectedTagIDs.isEmpty)
        print("PASS: rating draft validation, Unicode comment limit, tag retry/selection and unavailable tag removal")

        let model = PurchasesViewModel(service: fake, session: session)
        fake.list = { _, _ in currentPage }
        await model.reload(filter: .all, language: "ar")
        precondition(model.rows.map(\.coupon.id) == [910, 909] && !model.hasMore)
        precondition(model.totals == [.all: 2, .ready: 1, .used: 1, .ended: 0])
        // Global counts remain authoritative even when a status page contains only one row.
        let filteredData = #"{"coupons":[],"counts":{"all":2,"ready":1,"used":1,"ended":0},"pagination":{"total_items":1,"total_pages":1,"current_page":1}}"#
        fake.list = { _, _ in try JSONDecoder().decode(PurchasePage.self, from: Data(filteredData.utf8)) }
        await model.reload(filter: .used, language: "ar")
        precondition(model.totals == [.all: 2, .ready: 1, .used: 1, .ended: 0])
        fake.list = { _, page in try Self.page(page, pages: 2, coupons: coupon + "," + coupon) }
        await model.reload(filter: .ready, language: "en")
        precondition(model.rows.count == 2 && Set(model.rows.map(\.id)).count == 2)
        precondition(model.hasMore && model.totals[.ready] == 3)
        fake.list = { _, page in
            precondition(page == 2)
            throw APIError.server("Retry page 2")
        }
        await model.loadMore()
        precondition(model.rows.count == 2 && model.error != nil && model.hasMore)
        fake.list = { _, page in
            precondition(page == 2)
            return try Self.page(page, pages: 2)
        }
        await model.retry(language: "en")
        precondition(
            model.rows.count == 3 && Set(model.rows.map(\.id)).count == 3 && !model.hasMore && model.error == nil)

        var pending: CheckedContinuation<PurchasePage, Error>?
        fake.list = { status, _ in
            if status == .ready { return try await withCheckedThrowingContinuation { pending = $0 } }
            return try Self.page(coupons: "")
        }
        let older = Task { await model.reload(filter: .ready, language: "en") }
        while pending == nil { await Task.yield() }
        await model.reload(filter: .used, language: "en")
        let totalsBeforeStaleResponse = model.totals
        pending!.resume(returning: currentPage)
        await older.value
        precondition(model.filter == .used && model.rows.isEmpty && model.hasLoaded)
        precondition(model.totals == totalsBeforeStaleResponse, "Stale global counts must not overwrite current filters")

        pending = nil
        let expiredSession = Task { await model.reload(filter: .ready, language: "en") }
        while pending == nil { await Task.yield() }
        session.token = nil
        model.reset()
        pending!.resume(returning: currentPage)
        await expiredSession.value
        precondition(model.rows.isEmpty && model.totals.isEmpty && !model.hasLoaded && model.requiresSignIn)
        session.token = "two"
        fake.list = { _, _ in try Self.page(coupons: "") }
        await model.reload(filter: .all, language: "ar")
        precondition(model.rows.isEmpty && model.hasLoaded && !model.hasMore)

        var detailPending: CheckedContinuation<PurchaseDetail, Error>?
        let detailModel = PurchaseDetailViewModel(id: 4, status: .ready, service: fake, session: session)
        let decoded = PurchaseDetail(legacy: try JSONDecoder().decode(PurchaseCoupon.self, from: Data(coupon.utf8)))
        fake.detail = { _ in decoded }
        await detailModel.load(language: "ar")
        precondition(detailModel.purchase?.code == "0046" && detailModel.canShowCode)
        session.token = "three"
        precondition(detailModel.purchase == nil && !detailModel.canShowCode)
        fake.detail = { _ in try await withCheckedThrowingContinuation { detailPending = $0 } }
        let detailTask = Task { await detailModel.load(language: "en") }
        while detailPending == nil { await Task.yield() }
        session.token = nil
        detailPending!.resume(returning: decoded)
        await detailTask.value
        precondition(detailModel.purchase == nil)
        print(
            "PASS: duplicate purchased rows, pagination/retry, stale filter response, logout/session cache isolation, details/code session isolation"
        )
    }

    private static func requestBody(_ request: URLRequest) -> String {
        if let body = request.httpBody { return String(decoding: body, as: UTF8.self) }
        guard let stream = request.httpBodyStream else { return "" }
        stream.open()
        defer { stream.close() }
        var data = Data()
        var buffer = [UInt8](repeating: 0, count: 1024)
        while true {
            let count = stream.read(&buffer, maxLength: buffer.count)
            if count <= 0 { break }
            data.append(contentsOf: buffer.prefix(count))
        }
        return String(decoding: data, as: UTF8.self)
    }
}
