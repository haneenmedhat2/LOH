import Foundation

@MainActor enum CouponDetailsTests {
    static func run(client: APIClient) async throws {
        let fixture = try HomeServiceTests.fixture("coupon-196")
        let service = LOHHomeService(client: client)
        MockProtocol.handler = { request in
            precondition(request.url!.path == "/api/coupon/196" && request.httpMethod == "GET")
            precondition(request.url!.query == nil && request.httpBody == nil)
            precondition(request.value(forHTTPHeaderField: "Authorization") == "Bearer test-session")
            precondition(request.value(forHTTPHeaderField: "lang") == "ar")
            return (200, fixture)
        }
        let offer = try await service.detail(id: "196", token: "test-session", language: "ar")
        precondition(offer.id == "196" && offer.title == "عرض مطعم تيست" && offer.isRemote)
        precondition(offer.descriptionText == "عرض جديييييد" && offer.categoryID == 1 && offer.categoryName == "مطاعم")
        precondition(offer.merchant == "top store test" && offer.store?.id == 79 && offer.store?.isVerified == true)
        precondition(offer.merchantImage == offer.store?.image && offer.merchantImage?.hasSuffix("1792596021_7897.png") == true)
        precondition(offer.images.count == 1 && offer.images[0].id == 1 && offer.asset == offer.images[0].image)
        precondition(offer.asset.hasSuffix("1792656229_4056.png"))
        precondition(!offer.available && offer.availabilityStatus == " العرض غير متاح" && offer.isFavorite == false)
        precondition(offer.availableTimeText == nil && offer.fromTime == nil && offer.toTime == nil)
        precondition(offer.price == 10 && offer.originalPrice == 10 && offer.currency == "ريال" && offer.discount == 0)
        precondition(offer.serviceFee == 1 && offer.totalPrice == 11 && offer.payablePrice == 11)
        precondition(offer.features.map(\.title) == ["استخدام 500 مرات", "صالح 8833 أيام", "دفع آمن"])
        precondition(offer.includedItems.isEmpty && offer.includesText == nil)
        precondition(offer.terms?.items.count == 3 && offer.terms?.items.first == "يستخدم داخل الفرع فقط")
        precondition(offer.terms?.viewAllLabel == "عرض جميع الشروط")
        precondition(offer.branch?.name == "top store test" && offer.branch?.isOpen == false && offer.branch?.statusText == "مغلق الآن")
        precondition(offer.branch?.address == nil && offer.branch?.directionsDestination == nil)
        precondition(offer.branch?.latitude == nil && offer.branch?.longitude == nil && offer.branch?.directionsLabel == "الاتجاهات")
        precondition(!offer.hasRating && offer.ratingCount == 0 && offer.ratingText == nil && !offer.hasDistance)
        precondition(offer.distanceText == nil && offer.latitude == nil && offer.longitude == nil)
        precondition(offer.location == nil && offer.nearestCity == nil && offer.options.isEmpty)
        precondition(offer.fulfillmentType == "branch_pickup" && offer.hasAddress == false && offer.hasOptions == false)

        // Existing list/detail envelopes still use flat fields and string content.
        let decoder = JSONDecoder()
        let legacy = try decoder.decode(HomeOffer.self, from: Data(#"{"id":91,"name":"Legacy","price":8,"store_name":"Old store","image":"old.png","store_image":"logo.png","available":true,"description":"About","includes":"Coffee","conditions":"Terms","distance":1.5,"rate":4.5}"#.utf8))
        precondition(legacy.title == "Legacy" && legacy.merchant == "Old store" && legacy.asset == "old.png" && legacy.merchantImage == "logo.png")
        precondition(legacy.available && legacy.descriptionText == "About" && legacy.includesText == "Coffee" && legacy.conditionsText == "Terms")
        precondition(legacy.hasDistance && legacy.distance == 1.5 && legacy.hasRating && legacy.rating == 4.5 && legacy.payablePrice == 8)

        let populated = try decoder.decode(HomeOffer.self, from: Data(#"{"id":196,"name":"Old title","coupon_name":"New title","price":"10","original_price":20,"discount_percentage":"0","service_fee":"1","total_price":"12","available":false,"is_available":"1","available_time_text":"9–5","from_time":"09:00","to_time":"17:00","images":[{"id":"1","image":"one.png"},{"id":2,"image":"two.png"}],"store":{"id":"79","name":"Store","is_verified":"1"},"distance":"2 km","distance_value":"2","rating":"4.5","rating_count":"7","rating_text":"7 reviews","includes":["Coffee","Cake"],"branch":{"is_open":"1","lat":"24.7","lng":"46.6","directions_url":"https://maps.apple.com/?ll=24.7,46.6"},"have_address":"yes","have_option":"yes","options":[{"id":1,"name":"Large"}],"nearest_city":{"id":1,"name":"Riyadh"},"location":"Branch location"}"#.utf8))
        precondition(populated.title == "New title" && populated.available && populated.discount == 0)
        precondition(populated.images.count == 2 && populated.asset == "one.png" && populated.store?.isVerified == true)
        precondition(populated.serviceFee == 1 && populated.payablePrice == 12, "Use the server total when supplied")
        precondition(populated.availableTimeText == "9–5" && populated.fromTime == "09:00" && populated.toTime == "17:00")
        precondition(populated.hasDistance && populated.distance == 2 && populated.distanceText == "2 km")
        precondition(populated.hasRating && populated.rating == 4.5 && populated.ratingCount == 7 && populated.ratingText == "7 reviews")
        precondition(populated.includedItems == ["Coffee", "Cake"] && populated.includesText == nil)
        precondition(populated.branch?.isOpen == true && populated.branch?.latitude == 24.7 && populated.branch?.longitude == 46.6)
        precondition(populated.branch?.directionsDestination?.host == "maps.apple.com")
        precondition(populated.hasAddress == true && populated.hasOptions == true && populated.options.count == 1)
        precondition(populated.location == .string("Branch location") && populated.nearestCity == .object(["id": .number(1), "name": .string("Riyadh")]))

        let nullable = try decoder.decode(HomeOffer.self, from: Data(#"{"id":196,"price":10,"service_fee":1,"includes":null,"images":null,"store":null,"terms":null,"features":null,"branch":null,"options":null}"#.utf8))
        precondition(nullable.payablePrice == 11 && nullable.includedItems.isEmpty && nullable.images.isEmpty && nullable.features.isEmpty)
        precondition(nullable.store == nil && nullable.terms == nil && nullable.branch == nil && nullable.options.isEmpty)
        let badLink = try decoder.decode(HomeOfferBranch.self, from: Data(#"{"directions_url":"javascript:alert(1)"}"#.utf8))
        precondition(badLink.directionsDestination == nil)

        MockProtocol.handler = { _ in (200, fixture.replacingOccurrences(of: "\"id\": 196", with: "\"id\": 197")) }
        do { _ = try await service.detail(id: "196", token: nil, language: "ar"); preconditionFailure("Reject a response for a different coupon") }
        catch { }
        print("PASS: Supplied coupon details, nested store/images/branch, availability, pricing, text/array includes, metadata, legacy compatibility and requested-ID validation")
    }
}
