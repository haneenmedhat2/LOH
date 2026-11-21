import Foundation

enum OfferCategory: String, CaseIterable, Identifiable {
    case all, restaurants, cafes, entertainment, sport, spa, shopping, education, health
    static let homeCategories: [OfferCategory] = [.all, .restaurants, .cafes, .entertainment, .sport, .spa]
    var id: String { rawValue }
    var asset: String {
        switch self {
        case .all, .shopping, .education, .health: return "lohCategoryAll"
        case .restaurants: return "lohCategoryRestaurant"
        case .cafes: return "lohCategoryCafe"
        case .entertainment: return "lohCategoryEntertainment"
        case .sport: return "lohCategorySport"
        case .spa: return "lohCategorySpa"
        }
    }
}
enum OfferCity: String, CaseIterable, Identifiable {
    case tabuk, riyadh, jeddah, khobar, hail, abha
    var id: String { rawValue }
}
extension OfferCity {
    /// Counts displayed by the supplied preview design, not a live city inventory.
    var previewOfferCount: Int {
        switch self {
        case .tabuk: return 128
        case .riyadh: return 342
        case .jeddah: return 276
        case .khobar: return 184
        case .hail: return 96
        case .abha: return 64
        }
    }
}
enum OfferSort: String, CaseIterable, Identifiable {
    case nearest, discount, price, rating
    var id: String { rawValue }
}
struct OfferFilters: Hashable {
    var categoryID: Int?
    var staticPriceID: Int?
    var discountOptionID: Int?
    var ratingOptionID: Int?
    var categories: Set<OfferCategory> = []
    var minimumDistance: Double = 0
    var distance: Double = 10
    var minimumPrice: Double = 0
    var maximumPrice: Double = 500
    var hasMaximumPrice = false
    var discount = 0
    var availableOnly = false
    var endingToday = false
    var rating: Double = 0
    var count: Int {
        (categories.isEmpty && categoryID == nil ? 0 : 1) + (minimumDistance > 0 || distance < 10 ? 1 : 0)
        + (staticPriceID != nil || minimumPrice > 0 || maximumPrice != 500 || hasMaximumPrice ? 1 : 0)
        + (discountOptionID != nil || discount > 0 ? 1 : 0) + (availableOnly ? 1 : 0)
        + (endingToday ? 1 : 0) + (ratingOptionID != nil || rating > 0 ? 1 : 0)
    }
}
struct HomeOfferImage: Hashable {
    let id: Int?
    let image: String
}
struct HomeOfferStore: Hashable {
    let id: Int?
    let name: String?
    let image: String?
    let isVerified: Bool?
}
struct HomeOfferFeature: Decodable, Hashable {
    let key: String
    let title: String
}
struct HomeOfferTerms: Decodable, Hashable {
    let items: [String]
    let viewAllLabel: String?
    enum CodingKeys: String, CodingKey { case items, viewAllLabel = "view_all_label" }
}
struct HomeOfferBranch: Hashable {
    let name: String?
    let address: String?
    let isOpen: Bool?
    let statusText: String?
    let latitude: Double?
    let longitude: Double?
    let directionsLabel: String?
    let directionsURL: String?

    var directionsDestination: URL? {
        guard let directionsURL, let url = URL(string: directionsURL),
              ["https", "http"].contains(url.scheme?.lowercased() ?? ""),
              let host = url.host, !host.isEmpty else { return nil }
        return url
    }
}

/// Preserve option/location metadata until populated responses establish their presentation contract.
indirect enum HomeJSONValue: Decodable, Hashable {
    case null, bool(Bool), number(Double), string(String), array([HomeJSONValue]), object([String: HomeJSONValue])
    init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        if c.decodeNil() { self = .null }
        else if let value = try? c.decode(Bool.self) { self = .bool(value) }
        else if let value = try? c.decode(Double.self) { self = .number(value) }
        else if let value = try? c.decode(String.self) { self = .string(value) }
        else if let value = try? c.decode([HomeJSONValue].self) { self = .array(value) }
        else { self = .object(try c.decode([String: HomeJSONValue].self)) }
    }
}

struct HomeOffer: Identifiable, Hashable {
    let id: String
    let merchant: String
    let title: String
    let category: OfferCategory
    let asset: String
    let price: Double
    let originalPrice: Double
    let distance: Double
    let rating: Double
    let discount: Int
    var available = true
    var endsToday = false
    var searchTerms: String
    var categoryID: Int?
    var categoryName: String?
    var descriptionText: String?
    var conditionsText: String?
    var includesText: String?
    var merchantImage: String?
    var shareLink: String?
    var currency: String?
    var isFavorite: Bool?
    var endsIn: String?
    var endsInSeconds: Int?
    var expiresAt: Date?
    var images: [HomeOfferImage] = []
    var store: HomeOfferStore?
    var features: [HomeOfferFeature] = []
    var includedItems: [String] = []
    var terms: HomeOfferTerms?
    var branch: HomeOfferBranch?
    var availabilityStatus: String?
    var availableTimeText: String?
    var fromTime: String?
    var toTime: String?
    var distanceText: String?
    var ratingCount: Int?
    var ratingText: String?
    var serviceFee: Double?
    var totalPrice: Double?
    var fulfillmentType: String?
    var hasAddress: Bool?
    var hasOptions: Bool?
    var latitude: Double?
    var longitude: Double?
    var location: HomeJSONValue?
    var nearestCity: HomeJSONValue?
    var options: [HomeJSONValue] = []
    var hasDistance = true
    var hasRating = true
    var isRemote = false

    var payablePrice: Double { totalPrice ?? price + (serviceFee ?? 0) }

    static let samples: [HomeOffer] = [
        .init(id: "nawa", merchant: "Nawa Café", title: "dailyCoffee", category: .cafes, asset: "lohOfferDailyCoffee", price: 8, originalPrice: 16, distance: 1.2, rating: 4.8, discount: 50, searchTerms: "نواة كافيه coffee cookie cafe قهوة كوكي كافيهات nearby عروض قريبة"),
        .init(id: "grill", merchant: "Grill Mode", title: "burgerMeal", category: .restaurants, asset: "lohOfferBurgerMeal", price: 22, originalPrice: 29, distance: 0.85, rating: 4.7, discount: 25, searchTerms: "جريل مود burger lunch restaurant برجر غداء مطاعم nearby عروض قريبة"),
        .init(id: "sweet", merchant: "Sweet Corner", title: "cookieCoffee", category: .cafes, asset: "lohOfferCookieCoffee", price: 12, originalPrice: 20, distance: 1.8, rating: 4.5, discount: 40, searchTerms: "سويت كورنر coffee cookie dessert قهوة كوكي حلويات"),
        .init(id: "rose", merchant: "Rose Roastery", title: "latteCroissant", category: .cafes, asset: "lohSearchLatte", price: 14, originalPrice: 26, distance: 1.4, rating: 4.7, discount: 46, searchTerms: "محمصة روز coffee latte croissant قهوة لاتيه كرواسون محمصة روز"),
        .init(id: "holt", merchant: "Holt Café", title: "espresso", category: .cafes, asset: "lohSearchEspresso", price: 6, originalPrice: 10, distance: 2.1, rating: 4.6, discount: 40, searchTerms: "هولت كافيه coffee espresso cafe قهوة إسبريسو كافيه"),
        .init(id: "waffles", merchant: "Istahej Café", title: "waffles", category: .cafes, asset: "lohSearchWaffles", price: 17, originalPrice: 24, distance: 2.8, rating: 4.4, discount: 30, searchTerms: "استهج كافيه coffee waffles قهوة وافل استهج كافيه"),
        .init(id: "pancakes", merchant: "Sweet Corner", title: "pancakes", category: .cafes, asset: "lohOfferPancakes", price: 15, originalPrice: 30, distance: 2.4, rating: 4.7, discount: 50, endsToday: true, searchTerms: "سويت كورنر pancakes breakfast dessert coffee بان كيك فطور حلويات قهوة"),
        .init(id: "massage", merchant: "Relax Spa", title: "massage", category: .spa, asset: "lohOfferMassage", price: 120, originalPrice: 300, distance: 3.1, rating: 4.8, discount: 60, searchTerms: "ريلاكس سبا spa massage beauty سبا مساج جمال استرخاء"),
        .init(id: "cinema", merchant: "Cinema Park", title: "cinema", category: .entertainment, asset: "lohFavoriteCinema", price: 45, originalPrice: 70, distance: 4, rating: 4.6, discount: 36, searchTerms: "سينما بارك cinema entertainment weekend سينما ترفيه نشاطات")
    ]
}
enum OfferSearch {
    static func results(in offers: [HomeOffer], query: String, category: OfferCategory, filters: OfferFilters, sort: OfferSort) -> [HomeOffer] {
        let query = query.trimmingCharacters(in: .whitespacesAndNewlines)
        return offers.filter { offer in
            (category == .all || offer.category == category)
            && (filters.categories.isEmpty || filters.categories.contains(offer.category))
            && offer.distance >= filters.minimumDistance && offer.distance <= filters.distance
            && Double(offer.price) >= filters.minimumPrice
            && (!filters.hasMaximumPrice && filters.maximumPrice == 500 || Double(offer.price) <= filters.maximumPrice)
            && offer.discount >= filters.discount && offer.rating >= filters.rating
            && (!filters.availableOnly || offer.available) && (!filters.endingToday || offer.endsToday)
            && (query.isEmpty || "\(offer.merchant) \(offer.searchTerms)".localizedStandardContains(query))
        }.sorted { lhs, rhs in
            switch sort {
            case .nearest: return lhs.distance < rhs.distance
            case .discount: return lhs.discount > rhs.discount
            case .price: return lhs.price < rhs.price
            case .rating: return lhs.rating > rhs.rating
            }
        }
    }
}
