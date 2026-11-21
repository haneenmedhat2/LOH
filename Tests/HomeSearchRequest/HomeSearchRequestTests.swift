import Foundation

typealias APIParameters = [String: Any?]
enum HomeOfferFeed: String, Hashable { case search, nearby, endingSoon }

@main struct HomeSearchRequestTests {
    static func main() {
        let defaults = HomeSearchRequest().queryParameters(page: 1)
        precondition(defaults["min_distance"] == nil && defaults["max_distance"] == nil)
        for distance in [1.0, 5.0, 8.0] {
            var request = HomeSearchRequest()
            request.filters.distance = distance
            let query = request.queryParameters(page: 2)
            precondition(query["min_distance"] as? String == "0")
            precondition(query["max_distance"] as? String == String(distance))
            precondition(query["page"] as? Int == 2)
            request.feed = .nearby
            let nearby = request.queryParameters(page: 1)
            precondition(nearby["min_distance"] == nil && nearby["max_distance"] == nil)
        }
        var range = HomeSearchRequest()
        range.filters.minimumDistance = 3
        range.filters.distance = 8
        let query = range.queryParameters(page: 1)
        precondition(query["min_distance"] as? String == "3.0")
        precondition(query["max_distance"] as? String == "8.0")
        range.filters.distance = 10
        let minimumOnly = range.queryParameters(page: 1)
        precondition(minimumOnly["min_distance"] as? String == "3.0")
        precondition(minimumOnly["max_distance"] as? String == "10.0")
        var price = HomeSearchRequest()
        price.filters.minimumPrice = 700
        let minimumPriceOnly = price.queryParameters(page: 1)
        precondition(minimumPriceOnly["min_price"] as? String == "700.0" && minimumPriceOnly["max_price"] == nil)
        price.filters.minimumPrice = 0
        price.filters.hasMaximumPrice = true
        let maximumPrice = price.queryParameters(page: 1)
        precondition(maximumPrice["min_price"] == nil && maximumPrice["max_price"] as? String == "500.0")
        print("PASS: distance ranges send both bounds; default and other feeds omit distance parameters")
    }
}
