import Foundation

final class MockProtocol: URLProtocol {
    static var handler: ((URLRequest) throws -> (Int, String))!
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        do {
            let (status, body) = try Self.handler(request)
            client?.urlProtocol(self, didReceive: HTTPURLResponse(url: request.url!, statusCode: status, httpVersion: nil, headerFields: ["Content-Type": "application/json"])!, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: Data(body.utf8))
            client?.urlProtocolDidFinishLoading(self)
        } catch { client?.urlProtocol(self, didFailWithError: error) }
    }
    override func stopLoading() {}
}

@main struct APITests {
    static func main() async throws {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockProtocol.self]
        let session = URLSession(configuration: configuration)
        let client = APIClient(baseURL: URL(string: "https://example.invalid/api/")!, session: session)
        let service = LOHAuthService(client: client, language: { "ar" }, deviceID: { "test-installation" })
        let request = try client.urlRequest(AuthEndpoints.selectInterests(ids: [1, 2], token: "test-token"), language: "ar")
        let body = String(data: request.httpBody!, encoding: .utf8)!
        precondition(body.components(separatedBy: "name=\"interest_ids[]\"").count == 3)
        precondition(request.value(forHTTPHeaderField: "Authorization") == "Bearer test-token")
        precondition(request.value(forHTTPHeaderField: "lang") == "ar")
        precondition(request.value(forHTTPHeaderField: "x-api-key") == nil)
        precondition(request.value(forHTTPHeaderField: "Content-Type")!.contains("multipart/form-data; boundary="))
        MockProtocol.handler = { request in
            precondition(request.url!.path == "/api/select-city" && request.httpMethod == "POST")
            var data = request.httpBody ?? Data()
            if let stream = request.httpBodyStream {
                stream.open()
                defer { stream.close() }
                var buffer = [UInt8](repeating: 0, count: 4096)
                while true {
                    let count = stream.read(&buffer, maxLength: buffer.count)
                    if count <= 0 { break }
                    data.append(contentsOf: buffer.prefix(count))
                }
            }
            let body = String(decoding: data, as: UTF8.self)
            precondition(body.contains("name=\"city_id\"\r\n\r\n37\r\n"))
            precondition(!body.contains("city_ids") && !body.contains("name=\"lat\""))
            return (200, #"{"key":"success"}"#)
        }
        try await service.select(cities: true, ids: [37], token: "test-token")
        do {
            try await service.select(cities: true, ids: [1, 2], token: "test-token")
            preconditionFailure("Manual city selection must contain exactly one city")
        } catch { }
        let user = #"{"id":"7","name":"Test","token":"sample-token","is_notify":"1","cities":[],"interests":[]}"#
        for key in ["success", "needActive", "selectCity", "selectInterests"] {
            MockProtocol.handler = { request in
                precondition(request.url!.path == "/api/login" && request.httpMethod == "POST")
                return (200, "{\"key\":\"\(key)\",\"msg\":\"OK\",\"data\":\(user)}")
            }
            let response = try await service.login(phone: "551234567", countryCode: "+966", password: "password")
            precondition(response.key == key && response.data?.id == 7 && response.data?.isNotify == true)
        }
        for (status, response) in [(200, #"{"key":"blocked","msg":"Blocked"}"#), (400, #"{"key":"fail","msg":"Invalid"}"#), (500, "<html>Error</html>"), (200, #"{"key":"unknown","msg":"Unknown"}"#), (200, #"{"key":"success","data":{"id":"not-an-id"}}"#)] {
            MockProtocol.handler = { _ in (status, response) }
            do {
                let _: APIEnvelope<APIUser> = try await client.send(
                    AuthEndpoints.login(phone: "551234567", countryCode: "966", password: "x", deviceID: "test"),
                    language: "en")
                preconditionFailure("Expected failure")
            }
            catch { }
        }
        MockProtocol.handler = { request in
            precondition(request.httpMethod == "GET" && request.url!.path == "/api/resend-code")
            precondition(URLComponents(url: request.url!, resolvingAgainstBaseURL: false)!.queryItems == [.init(name: "phone", value: "551234567")])
            return (200, #"{"key":"success","msg":"Sent"}"#)
        }
        try await service.resend(phone: "551234567")
        MockProtocol.handler = { request in
            precondition(request.url!.path == "/api/activate")
            precondition(request.url!.query == "_method=patch")
            return (200, "{\"key\":\"selectCity\",\"data\":\(user)}")
        }
        let activated = try await service.activate(phone: "551234567", countryCode: "+966", code: "1234")
        precondition(activated.key == "selectCity")
        MockProtocol.handler = { _ in (200, #"{"key":"success","msg":"OK"}"#) }
        try await service.resetPassword(phone: "551234567", password: "newpassword")
        try await service.logout(token: "sample-token")
        print("PASS: multipart arrays, headers, auth response states, flexible decoding, server failures, resend and activation routes")
        try await SessionTests.run(service: service)
        try await IntrosTests.run(client: client)
        try await HomeServiceTests.run(client: client)
        try await CouponDetailsTests.run(client: client)
        try await HomeOfferDetailViewModelTests.run()
        try await MerchantTests.run(client: client)
        session.invalidateAndCancel()
    }
}
