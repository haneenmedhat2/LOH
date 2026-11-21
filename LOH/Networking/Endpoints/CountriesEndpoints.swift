import Foundation

struct CountriesEndpoints {
    private init() {}

    static func list() -> Endpoint<APIEnvelope<[CountriesDataModel]>> {
        Endpoint(path: "countries")
    }
}
