import Foundation

struct HomeSearchLoadKey: Hashable {
    let request: HomeSearchRequest
    let showsResults: Bool
    let language: String
}
