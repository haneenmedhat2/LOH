import Foundation

struct MerchantEndpoints {
    private init() {}
}

extension MerchantEndpoints {
    static
    func store(id: Int, categoryID: Int?, token: String?) -> Endpoint<APIEnvelope<HomeMerchant>> {
        var query: APIParameters = [:]
        if let categoryID { query["category_id"] = categoryID }
        return Endpoint(
            path: "store/\(id)",
            queries: query,
            headerType: .ifAuthourized(token: token)
        )
    }
    static
    func toggleFollow(id: Int, token: String) -> Endpoint<APIEnvelope<APIEmpty>> {
        return Endpoint(
            method: .post,
            path: "store/\(id)/toggle-follow",
            headerType: .authorized(token: token)
        )
    }
}
