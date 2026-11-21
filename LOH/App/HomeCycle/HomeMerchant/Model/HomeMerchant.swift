import Foundation

struct HomeMerchant: Decodable {
    let id: Int
    var name: String
    var shareLink: String?
    var image: String?
    var cover: String?
    var isVerified = false
    var isFollowed = false
    var followersCount = 0
    var storeType: String?
    var rating: Double?
    var ratingCount: Int?
    var ratingText: String?
    var distance: HomeMerchantDistance?
    var address: String?
    var locationText: String?
    var stats = HomeMerchantStats()
    var about: String?
    var categories: [HomeAPICategory] = []
    var offers: [HomeOffer] = []
    var location: HomeMerchantLocation?

    init(id: Int, name: String) {
        self.id = id
        self.name = name
        shareLink = nil
    }

    enum CodingKeys: String, CodingKey {
        case id, name, image, cover, rating, distance, address, stats, about, categories, offers, location
        case shareLink = "share_link"
        case isVerified = "is_verified", isFollowed = "is_followed", followersCount = "followers_count"
        case storeType = "store_type", ratingCount = "rating_count", ratingText = "rating_text"
        case distanceValue = "distance_value", locationText = "location_text"
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        guard let id = values.flexibleInt(.id), id > 0 else { throw APIError.invalidResponse }
        self.id = id
        name = try values.decode(String.self, forKey: .name)
        shareLink = try values.decodeIfPresent(String.self, forKey: .shareLink)
        image = try values.decodeIfPresent(String.self, forKey: .image)
        cover = try values.decodeIfPresent(String.self, forKey: .cover)
        isVerified = values.flexibleBool(.isVerified) ?? false
        isFollowed = values.flexibleBool(.isFollowed) ?? false
        followersCount = values.flexibleInt(.followersCount) ?? 0
        storeType = try values.decodeIfPresent(String.self, forKey: .storeType)
        rating = values.homeDouble(.rating)
        ratingCount = values.flexibleInt(.ratingCount)
        ratingText = try values.decodeIfPresent(String.self, forKey: .ratingText)
        distance =
            try values.decodeIfPresent(HomeMerchantDistance.self, forKey: .distance)
            ?? values.homeDouble(.distanceValue).map(HomeMerchantDistance.kilometers)
        address = try values.decodeIfPresent(String.self, forKey: .address)
        locationText = try values.decodeIfPresent(String.self, forKey: .locationText)
        stats = try values.decodeIfPresent(HomeMerchantStats.self, forKey: .stats) ?? HomeMerchantStats()
        about = try values.decodeIfPresent(String.self, forKey: .about)
        categories = try values.decodeIfPresent([HomeAPICategory].self, forKey: .categories) ?? []
        offers = try values.decodeIfPresent([HomeOffer].self, forKey: .offers) ?? []
        location = try values.decodeIfPresent(HomeMerchantLocation.self, forKey: .location)
        var seen = Set<String>()
        offers = offers.filter { seen.insert($0.id).inserted }
            .map { offer in
                var result = offer
                result.store = HomeOfferStore(id: id, name: name, image: image, isVerified: isVerified)
                return result
            }
    }
}

enum HomeMerchantDistance: Decodable, Equatable {
    case kilometers(Double)
    case text(String)

    init(from decoder: Decoder) throws {
        let value = try decoder.singleValueContainer()
        if let number = try? value.decode(Double.self), number.isFinite, number >= 0 {
            self = .kilometers(number)
        } else {
            let text = try value.decode(String.self)
            if let number = Double(text), number.isFinite, number >= 0 {
                self = .kilometers(number)
            } else {
                self = .text(text)
            }
        }
    }
}

struct HomeMerchantStats: Decodable {
    var offersCount: Int?
    var distance: HomeMerchantDistance?
    var rating: Double?

    init(offersCount: Int? = nil, distance: HomeMerchantDistance? = nil, rating: Double? = nil) {
        self.offersCount = offersCount
        self.distance = distance
        self.rating = rating
    }

    enum CodingKeys: String, CodingKey { case offersCount = "offers_count", distance, rating }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        offersCount = values.flexibleInt(.offersCount)
        distance = try values.decodeIfPresent(HomeMerchantDistance.self, forKey: .distance)
        rating = values.homeDouble(.rating)
    }
}

struct HomeMerchantLocation: Decodable {
    var address: String?
    var distance: HomeMerchantDistance?
    var latitude: Double?
    var longitude: Double?
    var directionsLabel: String?
    var directionsURL: String?

    var hasCoordinates: Bool { latitude != nil && longitude != nil }

    init(address: String? = nil, distance: HomeMerchantDistance? = nil) {
        self.address = address
        self.distance = distance
    }

    enum CodingKeys: String, CodingKey {
        case address, distance, latitude = "lat", longitude = "lng"
        case directionsLabel = "directions_label", directionsURL = "directions_url"
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        address = try values.decodeIfPresent(String.self, forKey: .address)
        distance = try values.decodeIfPresent(HomeMerchantDistance.self, forKey: .distance)
        latitude = values.homeDouble(.latitude)
        longitude = values.homeDouble(.longitude)
        directionsLabel = try values.decodeIfPresent(String.self, forKey: .directionsLabel)
        directionsURL = try values.decodeIfPresent(String.self, forKey: .directionsURL)
    }

    var url: URL? {
        if let directionsURL, let url = URL(string: directionsURL),
            ["https", "http"].contains(url.scheme?.lowercased() ?? ""), url.host?.isEmpty == false
        {
            return url
        }
        guard let latitude, let longitude,
            (-90...90).contains(latitude), (-180...180).contains(longitude)
        else { return nil }
        var url = URLComponents(string: "https://maps.apple.com/")!
        url.queryItems = [.init(name: "ll", value: "\(latitude),\(longitude)")]
        if let address, !address.isEmpty { url.queryItems?.append(.init(name: "q", value: address)) }
        return url.url
    }
}
