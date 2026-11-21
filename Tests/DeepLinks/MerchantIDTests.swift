import Combine
import Foundation

struct HomeOffer { struct Store { let id: Int? }; let store: Store?; var categoryID: Int? = nil }
struct HomeMerchant { let id: Int; var offers: [HomeOffer] = []; var isFollowed = false; var followersCount = 0 }
struct Endpoint<T> { let id: Int }
enum APIError: LocalizedError { case invalidResponse }
extension UserDefaults { static var accessToken: String? { nil } }
enum MerchantEndpoints {
    static func store(id: Int, categoryID: Int?, token: String?) -> Endpoint<HomeMerchant> { Endpoint(id: id) }
    static func toggleFollow(id: Int, token: String) -> Endpoint<Bool> { Endpoint(id: id) }
}
struct DefaultResponseHandler {
    @MainActor static var load: (Int) async throws -> HomeMerchant = { HomeMerchant(id: $0) }
    func data<T>(from endpoint: Endpoint<T>, language: String) async throws -> T { try await Self.load(endpoint.id) as! T }
    func perform(_ endpoint: Endpoint<Bool>, language: String) async throws {}
}

@main struct MerchantIDTests {
    @MainActor static func main() async {
        var loadedID: Int?
        let direct = HomeMerchantViewModel(merchantID: 78, onLoad: { loadedID = $0.id })
        await direct.load(language: "ar")
        precondition(direct.seed == nil && direct.merchant?.id == 78 && loadedID == 78)
        await direct.toggleFollow(language: "ar")
        precondition(direct.showsLogin)
        let seeded = HomeMerchantViewModel(offer: HomeOffer(store: .init(id: 79)))
        await seeded.load(language: "en")
        precondition(seeded.merchant?.id == 79)
        let invalid = HomeMerchantViewModel(merchantID: 0)
        await invalid.load(language: "en")
        precondition(invalid.merchant == nil && invalid.error != nil)
        DefaultResponseHandler.load = { _ in HomeMerchant(id: 999) }
        let mismatched = HomeMerchantViewModel(merchantID: 78)
        await mismatched.load(language: "en")
        precondition(mismatched.merchant == nil && mismatched.error != nil)
        print("PASS: direct merchant IDs load and validate the server response, seeded routes and guest follow remain supported")
    }
}
