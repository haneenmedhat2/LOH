import Foundation

enum FAQEndpoints {
    static func list() -> Endpoint<APIEnvelope<FAQListData>> {
        Endpoint(path: "faqs")
    }

    static func detail(id: Int) throws -> Endpoint<APIEnvelope<FAQQuestion>> {
        guard id > 0 else { throw APIError.invalidResponse }
        return Endpoint(path: "faqs/\(id)")
    }
}
