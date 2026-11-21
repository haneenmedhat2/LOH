import Foundation

enum AccountDocumentEndpoint: String, CaseIterable {
    case privacy = "privacy-page"
    case terms = "terms-page"
    case about
    case securityPrivacy = "security-privacy"
}

struct AccountEndpoints {
    private init() {}
}

extension AccountEndpoints {
    static
    func userStats(token: String) -> Endpoint<APIEnvelope<MoreUserStats>> {
        return Endpoint(
            path: "user-stats",
            headerType: .authorized(token: token)
        )
    }
    static
    func cashback(token: String) -> Endpoint<APIEnvelope<MoreCashbackBalance>> {
        return Endpoint(
            path: "cash-back",
            headerType: .authorized(token: token)
        )
    }
    static
    func join(fields: [(String, String)], token: String) -> Endpoint<APIEnvelope<APIEmpty>> {
        let body = fields.reduce(into: APIParameters()) { parameters, field in
            parameters[field.0] = field.1
        }
        return Endpoint(
            method: .post,
            path: "join-us",
            body: body,
            headerType: .authorized(token: token)
        )
    }
    static
    func deleteAccount(token: String) -> Endpoint<APIEnvelope<APIEmpty>> {
        return Endpoint(
            method: .delete,
            path: "delete-account",
            headerType: .authorized(token: token)
        )
    }
    static
    func updatePassword(current: String, new: String, token: String) -> Endpoint<APIEnvelope<APIEmpty>> {
        return Endpoint(
            method: .patch,
            path: "update-password",
            body: ["old_password": current, "password": new],
            headerType: .authorized(token: token)
        )
    }
    static
    func updateProfile(fields: [(String, String)], files: [UploadData], token: String) -> Endpoint<APIEnvelope<APIUser>> {
        var body = fields.reduce(into: APIParameters()) { parameters, field in
            parameters[field.0] = field.1
        }
        body["_method"] = "put"
        return Endpoint(
            method: .post,
            path: "update-profile",
            body: body,
            headerType: .authorized(token: token),
            uploads: files
        )
    }
    static
    func changeLanguage(_ value: String, token: String) -> Endpoint<APIEnvelope<APIEmpty>> {
        return Endpoint(
            method: .patch,
            path: "change-lang",
            queries: ["lang": value],
            headerType: .authorized(token: token)
        )
    }
    static
    func document(_ endpoint: AccountDocumentEndpoint) -> Endpoint<APIEnvelope<AccountDocumentContent>> {
        return Endpoint(
            path: endpoint.rawValue
        )
    }
}
