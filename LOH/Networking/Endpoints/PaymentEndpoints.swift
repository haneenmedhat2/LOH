import Foundation

struct PaymentEndpoints {
    private init() {}
}

extension PaymentEndpoints {
    static
    func list(token: String) -> Endpoint<APIEnvelope<AccountCardList>> {
        return Endpoint(
            path: "payment-cards",
            headerType: .authorized(token: token)
        )
    }
    static
    func add(fields: [(String, String)], token: String) -> Endpoint<APIEnvelope<APIEmpty>> {
        let body = fields.reduce(into: APIParameters()) { parameters, field in
            parameters[field.0] = field.1
        }
        return Endpoint(
            method: .post,
            path: "add-payment-cards",
            body: body,
            headerType: .authorized(token: token)
        )
    }
    static
    func setDefault(id: Int, token: String) -> Endpoint<APIEnvelope<APIEmpty>> {
        return Endpoint(
            method: .post,
            path: "payment-cards/\(id)/set-default",
            body: ["_method": "patch"],
            headerType: .authorized(token: token)
        )
    }
    static
    func setDefault(id: Int, fields: [(String, String)], token: String) -> Endpoint<APIEnvelope<APIEmpty>> {
        var body = fields.reduce(into: APIParameters()) { parameters, field in
            parameters[field.0] = field.1
        }
        body["_method"] = "patch"
        return Endpoint(
            method: .post,
            path: "payment-cards/\(id)/set-default",
            body: body,
            headerType: .authorized(token: token)
        )
    }
    static
    func rename(id: Int, name: String, token: String) -> Endpoint<APIEnvelope<APIEmpty>> {
        return Endpoint(
            method: .patch,
            path: "payment-cards/\(id)/rename",
           // queries: ["_method": "patch"],
            body: [
                "holder_name": name,
                "_method": "patch"
            ],
            headerType: .authorized(token: token)
        )
    }
    static
    func delete(id: Int, token: String) -> Endpoint<APIEnvelope<APIEmpty>> {
        return Endpoint(
            method: .delete,
            path: "delete-payment-cards/\(id)",
            headerType: .authorized(token: token)
        )
    }
}
