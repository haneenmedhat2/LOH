import Foundation

extension KeyedDecodingContainer {
    func flexibleInt(_ key: Key) -> Int? {
        if let value = try? decode(Int.self, forKey: key) { return value }
        if let value = try? decode(String.self, forKey: key) { return Int(value) }
        return nil
    }
    func flexibleBool(_ key: Key) -> Bool? {
        if let value = try? decode(Bool.self, forKey: key) { return value }
        if let value = flexibleInt(key) { return value != 0 }
        if let value = try? decode(String.self, forKey: key) { return ["true", "yes"].contains(value.lowercased()) }
        return nil
    }
}

enum APILogger {
    static func decodingFailure(_ error: Error, response: Data) -> String {
        let path: [CodingKey]
        let reason: String
        switch error {
        case DecodingError.typeMismatch(let type, let context):
            path = context.codingPath
            reason = "expected \(type)"
        case DecodingError.valueNotFound(let type, let context):
            path = context.codingPath
            reason = "expected non-null \(type)"
        case DecodingError.keyNotFound(let key, let context):
            path = context.codingPath + [key]
            reason = "missing required field"
        case DecodingError.dataCorrupted(let context):
            path = context.codingPath
            reason = "invalid field format"
        default:
            return "response validation failed (\(type(of: error)))"
        }
        var value: Any? = try? JSONSerialization.jsonObject(with: response, options: [.fragmentsAllowed])
        for key in path {
            if let array = value as? [Any], let index = key.intValue, array.indices.contains(index) {
                value = array[index]
            } else {
                value = (value as? [String: Any])?[key.stringValue]
            }
        }
        let kind: String
        switch value {
        case nil: kind = "missing"
        case is NSNull: kind = "null"
        case is [String: Any]: kind = "object"
        case is [Any]: kind = "array"
        case is String: kind = "string"
        case let number as NSNumber:
            kind = String(cString: number.objCType) == "c" ? "boolean" : "number"
        default: kind = "unknown"
        }
        let field = path.isEmpty ? "$" : path.map(\.stringValue).joined(separator: ".")
        return "\(field): \(reason), received \(kind)"
    }

    /// Preserve the original JSON values and structure in development logs.
    static func json(_ value: Any) -> String {
        guard let data = try? JSONSerialization.data(withJSONObject: value, options: [.prettyPrinted, .sortedKeys, .fragmentsAllowed]),
              let text = String(data: data, encoding: .utf8) else { return "[Unserializable log data]" }
        return text
    }
    static func request(_ request: URLRequest, queries: [String: Any], body: [String: Any]) {
        #if DEBUG
        print("""

        ====================================
        🚀🚀FULL REQUEST COMPONENETS:::

        URL:: \(request.url?.absoluteString ?? "No URL Found")
        ---------------------------------
        Method:: \(request.httpMethod ?? "No httpMethod")
        ---------------------------------
        Header::
        \(json(request.allHTTPHeaderFields ?? [:]))
        ---------------------------------
        Queries::
        \(json(queries))
        ---------------------------------
        Body::
        \(json(body))

        ====================================

        """)
        #endif
    }
    static func printApiResponse(_ responseData: Data?, for url: String, statusCode: Int? = nil) {
        #if DEBUG
        if let statusCode { print("HTTP \(statusCode) — \(url)") }
        guard let responseData else {
            print("\n\n====================================\n⚡️⚡️RESPONSE FOR \(url) IS::\n", responseData as Any, "\n====================================\n\n")
            return
        }
        if let object = try? JSONSerialization.jsonObject(with: responseData, options: [.fragmentsAllowed]) {
            let text = json(object)
            print("\n\n====================================\n⚡️⚡️RESPONSE FOR \(url) IS::\n", text, "\n====================================\n\n")
            return
        }
        print("\n\n====================================\n⚡️⚡️RESPONSE FOR \(url) IS::\n[Non-JSON response: \(responseData.count) bytes]\n====================================\n\n")
        #endif
    }
}
