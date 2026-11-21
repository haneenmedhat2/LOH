import Foundation

// Server IDs are never inferred from the order or translated name of a category.
struct HomeAPICategory: Decodable, Identifiable, Hashable {
    let id: Int
    let name: String
    let image: String?
    init(id: Int, name: String, image: String? = nil) {
        self.id = id
        self.name = name
        self.image = image
    }
    enum CodingKeys: String, CodingKey { case id, name, image }
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        guard let id = c.flexibleInt(.id) else { throw APIError.invalidResponse }
        self.id = id
        name = try c.decode(String.self, forKey: .name)
        image = try c.decodeIfPresent(String.self, forKey: .image)
    }
}

struct HomeBanner: Decodable, Identifiable {
    let id: Int
    let title: String?
    let description: String?
    let image: String?
    let iosImage: String?
    let androidImage: String?
    let type: String?
    let couponID: Int?
    let couponName: String?
    let link: String?
    let startAt: String?
    let endAt: String?
    enum CodingKeys: String, CodingKey {
        case id, title, description, image, type, link
        case iosImage = "ios_image", androidImage = "android_image"
        case couponID = "coupon_id", couponName = "coupon_name"
        case startAt = "start_at", endAt = "end_at"
    }
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        guard let id = c.flexibleInt(.id) else { throw APIError.invalidResponse }
        self.id = id
        title = try c.decodeIfPresent(String.self, forKey: .title)
        description = try c.decodeIfPresent(String.self, forKey: .description)
        iosImage = try c.decodeIfPresent(String.self, forKey: .iosImage)
        androidImage = try c.decodeIfPresent(String.self, forKey: .androidImage)
        image = try iosImage ?? c.decodeIfPresent(String.self, forKey: .image)
        type = try c.decodeIfPresent(String.self, forKey: .type)
        couponID = c.flexibleInt(.couponID)
        couponName = try c.decodeIfPresent(String.self, forKey: .couponName)
        link = try c.decodeIfPresent(String.self, forKey: .link)
        startAt = try c.decodeIfPresent(String.self, forKey: .startAt)
        endAt = try c.decodeIfPresent(String.self, forKey: .endAt)
    }
}
struct HomeUser: Decodable {
    let name: String?
    let greeting: String?
    let greetingSubtitle: String?
    let image: String?
    enum CodingKeys: String, CodingKey { case name, greeting, image, greetingSubtitle = "greeting_subtitle" }
}
struct HomeCashback: Decodable {
    let image: String?
    let title: String?
    let subtitle: String?
    let button: String?
}
struct HomePageData: Decodable {
    let user: HomeUser?
    let city: HomeAPICategory?
    let categories: [HomeAPICategory]
    let banners: [HomeBanner]
    let nearby: [HomeOffer]
    let endingSoon: [HomeOffer]
    let notificationsCount: Int
    let cartCount: Int
    let showAd: Bool?
    let cashback: HomeCashback?
    enum CodingKeys: String, CodingKey {
        case user, city, categories, banners, cashback
        case nearby = "near_you", endingSoon = "ending_soon", notificationsCount = "notifications_count"
        case cartCount = "cart_count", showAd = "show_ad"
    }
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        user = try c.decodeIfPresent(HomeUser.self, forKey: .user)
        city = try c.decodeIfPresent(HomeAPICategory.self, forKey: .city)
        categories = try c.decodeIfPresent([HomeAPICategory].self, forKey: .categories) ?? []
        banners = try c.decodeIfPresent([HomeBanner].self, forKey: .banners) ?? []
        nearby = try c.decodeIfPresent([HomeOffer].self, forKey: .nearby) ?? []
        endingSoon = try c.decodeIfPresent([HomeOffer].self, forKey: .endingSoon) ?? []
        notificationsCount = c.flexibleInt(.notificationsCount) ?? 0
        cartCount = c.flexibleInt(.cartCount) ?? 0
        showAd = c.flexibleBool(.showAd)
        cashback = try c.decodeIfPresent(HomeCashback.self, forKey: .cashback)
    }
}
struct HomePagination: Decodable {
    let current: Int
    let pages: Int
    let total: Int
    enum CodingKeys: String, CodingKey { case current = "current_page", pages = "total_pages", total = "total_items" }
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        current = c.flexibleInt(.current) ?? 1
        pages = c.flexibleInt(.pages) ?? 1
        total = c.flexibleInt(.total) ?? 0
    }
}
struct HomeOfferPage: Decodable {
    let coupons: [HomeOffer]
    let pagination: HomePagination?
    let total: Int?
    let cityName: String?
    enum CodingKeys: String, CodingKey { case coupons, pagination, total, cityName = "city_name" }

    init(coupons: [HomeOffer], pagination: HomePagination?, total: Int? = nil, cityName: String? = nil) {
        self.coupons = coupons; self.pagination = pagination
        self.total = total; self.cityName = cityName
    }
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        coupons = try c.decode([HomeOffer].self, forKey: .coupons)
        pagination = try c.decodeIfPresent(HomePagination.self, forKey: .pagination)
        total = c.flexibleInt(.total)
        cityName = try c.decodeIfPresent(String.self, forKey: .cityName)
    }
}
struct HomeCategoryPage: Decodable {
    let categories: [HomeAPICategory]
    let pagination: HomePagination?
}
struct HomeFilterGroup: Decodable, Identifiable {
    let type: String
    let title: String
    let options: [HomeFilterOption]
    var id: String { type }
}
struct HomeFilterOption: Decodable, Identifiable {
    let id: Int
    let name: String
    let minimum: Double?
    let maximum: Double?
    enum CodingKeys: String, CodingKey { case id, name, minimum = "min_value", maximum = "max_value" }
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        guard let id = c.flexibleInt(.id) else { throw APIError.invalidResponse }
        self.id = id
        name = try c.decode(String.self, forKey: .name)
        minimum = c.homeDouble(.minimum)
        maximum = c.homeDouble(.maximum)
    }
}

struct HomeSearchRequest: Hashable {
    var feed: HomeOfferFeed = .search
    var query = ""
    var cityID: Int?
    var categoryID: Int?
    var filters = OfferFilters()
    var sort: OfferSort?

    func queryParameters(page: Int) -> APIParameters {
        var parameters: APIParameters = ["page": page]
        func add(_ name: String, _ value: String) { parameters[name] = value }
        if let cityID { add("city_id", String(cityID)) }
        if let id = filters.categoryID ?? categoryID { add("category_id", String(id)) }
        if feed == .search {
            let name = query.trimmingCharacters(in: .whitespacesAndNewlines)
            if !name.isEmpty { add("name", name) }
            // Defaults mean no restriction, rather than an implicit price/distance cap.
            if let id = filters.staticPriceID { add("static_price", String(id)) }
            else {
                if filters.minimumPrice > 0 { add("min_price", String(filters.minimumPrice)) }
                if filters.hasMaximumPrice || filters.maximumPrice != 500 { add("max_price", String(filters.maximumPrice)) }
            }
            if filters.minimumDistance > 0 || filters.distance < 10 {
                // The API validates the maximum against a supplied minimum.
                add("min_distance", filters.minimumDistance == 0 ? "0" : String(filters.minimumDistance))
                add("max_distance", String(filters.distance))
            }
            // These parameters reference static-filter options, not their displayed thresholds.
            if let id = filters.discountOptionID { add("discount", String(id)) }
            if let id = filters.ratingOptionID { add("rate", String(id)) }
            if filters.availableOnly { add("available_now", "1") }
            if filters.endingToday { add("ending_today", "1") }
            switch sort {
            case .nearest: add("sort", "nearest")
            case .price: add("sort", "price_low")
            case .discount, .rating, .none: break
            }
        }
        return parameters
    }
}
extension KeyedDecodingContainer {
    func homeDouble(_ key: Key) -> Double? {
        if let n = try? decode(Double.self, forKey: key), n.isFinite { return n }
        if let s = try? decode(String.self, forKey: key), let n = Double(s), n.isFinite { return n }
        return nil
    }
}
extension HomeOffer: Decodable {
    enum CodingKeys: String, CodingKey {
        case id, name, image, price, description, available, rate, rating, distance, conditions, includes, currency
        case images, store, features, terms, branch, about, options, location
        case couponName = "coupon_name", isAvailable = "is_available", availabilityStatus = "availability_status"
        case availableTimeText = "available_time_text", fromTime = "from_time", toTime = "to_time"
        case distanceValue = "distance_value", ratingCount = "rating_count", ratingText = "rating_text"
        case serviceFee = "service_fee", totalPrice = "total_price", fulfillmentType = "fulfillment_type"
        case hasAddress = "have_address", hasOptions = "have_option", latitude = "lat", longitude = "lng", nearestCity = "nearest_city"
        case merchant = "store_name", originalPrice = "original_price", oldPrice = "old_price"
        case categoryID = "category_id", categoryName = "category_name", merchantImage = "store_image"
        case discount = "discount_amount", discountType = "discount_type", shareLink = "share_link"
        case listedDiscount = "discount", isFavorite = "is_favorite"
        case discountPercentage = "discount_percentage"
        case endsIn = "ends_in", endsInSeconds = "ends_in_seconds"
        case expiresAt = "time_appearance_finish_at_date_time"
    }
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        guard let id = c.flexibleInt(.id), let price = c.homeDouble(.price), price >= 0 else { throw APIError.invalidResponse }
        self.id = String(id)
        // Home's compact offer summaries can omit the name; details load separately by ID.
        title = try c.decodeIfPresent(String.self, forKey: .couponName) ?? c.decodeIfPresent(String.self, forKey: .name) ?? ""
        store = try c.decodeIfPresent(HomeOfferStore.self, forKey: .store)
        images = try c.decodeIfPresent([HomeOfferImage].self, forKey: .images) ?? []
        merchant = try store?.name ?? c.decodeIfPresent(String.self, forKey: .merchant) ?? ""
        asset = try images.first?.image ?? c.decodeIfPresent(String.self, forKey: .image) ?? ""
        self.price = price
        currency = try c.decodeIfPresent(String.self, forKey: .currency)
        isFavorite = c.flexibleBool(.isFavorite)
        endsIn = try c.decodeIfPresent(String.self, forKey: .endsIn)
        endsInSeconds = c.flexibleInt(.endsInSeconds)
        originalPrice = c.homeDouble(.originalPrice) ?? c.homeDouble(.oldPrice) ?? price
        category = .all
        categoryID = c.flexibleInt(.categoryID)
        categoryName = try c.decodeIfPresent(String.self, forKey: .categoryName)
        descriptionText = try c.decodeIfPresent(String.self, forKey: .about) ?? c.decodeIfPresent(String.self, forKey: .description)
        merchantImage = try store?.image ?? c.decodeIfPresent(String.self, forKey: .merchantImage)
        shareLink = try c.decodeIfPresent(String.self, forKey: .shareLink)
        conditionsText = try c.decodeIfPresent(String.self, forKey: .conditions)
        if let text = try? c.decode(String.self, forKey: .includes) { includesText = text }
        else { includedItems = try c.decodeIfPresent([String].self, forKey: .includes) ?? [] }
        features = try c.decodeIfPresent([HomeOfferFeature].self, forKey: .features) ?? []
        terms = try c.decodeIfPresent(HomeOfferTerms.self, forKey: .terms)
        branch = try c.decodeIfPresent(HomeOfferBranch.self, forKey: .branch)
        availabilityStatus = try c.decodeIfPresent(String.self, forKey: .availabilityStatus)
        availableTimeText = try c.decodeIfPresent(String.self, forKey: .availableTimeText)
        fromTime = try c.decodeIfPresent(String.self, forKey: .fromTime)
        toTime = try c.decodeIfPresent(String.self, forKey: .toTime)
        let distance = c.homeDouble(.distanceValue) ?? c.homeDouble(.distance)
        if c.homeDouble(.distance) == nil { distanceText = try c.decodeIfPresent(String.self, forKey: .distance) }
        let rating = c.homeDouble(.rating) ?? c.homeDouble(.rate)
        ratingCount = c.flexibleInt(.ratingCount)
        ratingText = try c.decodeIfPresent(String.self, forKey: .ratingText)
        serviceFee = c.homeDouble(.serviceFee)
        totalPrice = c.homeDouble(.totalPrice)
        fulfillmentType = try c.decodeIfPresent(String.self, forKey: .fulfillmentType)
        hasAddress = c.flexibleBool(.hasAddress)
        hasOptions = c.flexibleBool(.hasOptions)
        latitude = c.homeDouble(.latitude); longitude = c.homeDouble(.longitude)
        location = try c.decodeIfPresent(HomeJSONValue.self, forKey: .location)
        nearestCity = try c.decodeIfPresent(HomeJSONValue.self, forKey: .nearestCity)
        options = try c.decodeIfPresent([HomeJSONValue].self, forKey: .options) ?? []
        self.distance = distance ?? 0; self.rating = rating ?? 0
        hasDistance = distance != nil; hasRating = rating != nil
        available = c.flexibleBool(.isAvailable) ?? c.flexibleBool(.available) ?? false
        if let timestamp = c.homeDouble(.expiresAt) { expiresAt = Date(timeIntervalSince1970: timestamp) }
        else if let seconds = endsInSeconds { expiresAt = Date().addingTimeInterval(TimeInterval(max(0, seconds))) }
        endsToday = expiresAt.map { Calendar.current.isDateInToday($0) } ?? false
        let type = try c.decodeIfPresent(String.self, forKey: .discountType)
        if let percentage = c.homeDouble(.discountPercentage) {
            discount = Int(max(0, min(100, percentage)))
        } else if originalPrice > price && originalPrice > 0 {
            discount = Int(((originalPrice - price) / originalPrice * 100).rounded())
        } else if type == "percentage" || type == "ratio" {
            discount = Int(max(0, min(100, c.homeDouble(.discount) ?? 0)))
        } else if let percentage = c.homeDouble(.listedDiscount) {
            discount = Int(max(0, min(100, percentage)))
        } else { discount = 0 }
        searchTerms = [title, merchant, categoryName ?? ""].joined(separator: " ")
        isRemote = true
    }
}

extension HomeOfferImage: Decodable {
    enum CodingKeys: String, CodingKey { case id, image }
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = c.flexibleInt(.id)
        image = try c.decode(String.self, forKey: .image)
    }
}
extension HomeOfferStore: Decodable {
    enum CodingKeys: String, CodingKey { case id, name, image, isVerified = "is_verified" }
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = c.flexibleInt(.id)
        name = try c.decodeIfPresent(String.self, forKey: .name)
        image = try c.decodeIfPresent(String.self, forKey: .image)
        isVerified = c.flexibleBool(.isVerified)
    }
}
extension HomeOfferBranch: Decodable {
    enum CodingKeys: String, CodingKey {
        case name, address, isOpen = "is_open", statusText = "status_text", latitude = "lat", longitude = "lng"
        case directionsLabel = "directions_label", directionsURL = "directions_url"
    }
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        name = try c.decodeIfPresent(String.self, forKey: .name)
        address = try c.decodeIfPresent(String.self, forKey: .address)
        isOpen = c.flexibleBool(.isOpen)
        statusText = try c.decodeIfPresent(String.self, forKey: .statusText)
        latitude = c.homeDouble(.latitude); longitude = c.homeDouble(.longitude)
        directionsLabel = try c.decodeIfPresent(String.self, forKey: .directionsLabel)
        directionsURL = try c.decodeIfPresent(String.self, forKey: .directionsURL)
    }
}

struct HomeFavoriteResult: Decodable {
    let id: Int
    let isFavorite: Bool
    enum CodingKeys: String, CodingKey { case id, isFavorite = "is_favorite" }
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        guard let id = c.flexibleInt(.id), let favorite = c.flexibleBool(.isFavorite) else {
            throw APIError.invalidResponse
        }
        self.id = id
        isFavorite = favorite
    }
}

