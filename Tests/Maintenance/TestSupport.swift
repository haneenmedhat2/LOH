import Foundation

// Only the transport and UI localization are substituted. The production handler,
// endpoint, response decoder and maintenance state machine are compiled unchanged.
enum RequestMethod: String { case get = "GET", post = "POST", patch = "PATCH", put = "PUT", delete = "DELETE" }
typealias APIParameters = [String: Sendable?]
struct UploadData {}
enum RequestHeaderType {
    case authorized(token: String), unauthorized, ifAuthourized(token: String?)
}
protocol Requestable {
    var method: RequestMethod { get }
    var path: String { get }
    var body: APIParameters? { get }
}
struct DefaultNetworkExecuter: NetworkExecuter {
    func execute(_ request: any Requestable, progress: ((Int) -> Void)?) async throws -> Data {
        fatalError("Tests must inject their transport")
    }
}
enum APILogger {
    static func printApiResponse(_ data: Data, for path: String) {}
}
extension String { var localized: String { self } }

actor StubNetwork: NetworkExecuter {
    struct Call {
        let method: RequestMethod
        let path: String
        let hasBody: Bool
    }
    private var responses: [Result<Data, Error>]
    private(set) var calls: [Call] = []

    init(_ json: [String]) {
        responses = json.map { .success(Data($0.utf8)) }
    }

    func execute(_ request: any Requestable, progress: ((Int) -> Void)?) async throws -> Data {
        calls.append(Call(method: request.method, path: request.path, hasBody: request.body != nil))
        guard !responses.isEmpty else { throw URLError(.notConnectedToInternet) }
        return try responses.removeFirst().get()
    }
}
