import Foundation

@main
struct HomeCatalogTests {
    @MainActor static func main() {
        let offers = HomeOffer.samples
        func search(_ query: String = "", _ filters: OfferFilters = OfferFilters(), category: OfferCategory = .all, sort: OfferSort = .nearest) -> [HomeOffer] {
            OfferSearch.results(in: offers, query: query, category: category, filters: filters, sort: sort)
        }
        assert(Set(offers.map(\.id)).count == offers.count)
        assert(search("قهوة").contains { $0.id == "nawa" })
        assert(search("COFFEE").contains { $0.id == "nawa" })
        assert(search("  Nawa  ").map(\.id) == ["nawa"])
        assert(search("a product that does not exist").isEmpty)
        assert(search(category: .restaurants).allSatisfy { $0.category == .restaurants })
        assert(search(category: .sport).isEmpty)
        for category in [OfferCategory.shopping, .education, .health] {
            var selected = OfferFilters(); selected.categories = [category]
            assert(search("", selected).isEmpty)
        }
        var pricePreset = OfferFilters(); pricePreset.minimumPrice = 20; pricePreset.maximumPrice = 50
        assert(Set(search("", pricePreset).map(\.id)) == ["grill", "cinema"])
        assert(OfferCategory.homeCategories.count == 6)
        var filter = OfferFilters()
        filter.categories = [.cafes]; filter.maximumPrice = 14; filter.discount = 45; filter.availableOnly = true
        assert(Set(search("", filter).map(\.id)) == ["nawa", "rose"])
        filter.distance = 1.3
        assert(search("", filter).map(\.id) == ["nawa"])
        var distanceRange = OfferFilters()
        distanceRange.minimumDistance = 2
        distanceRange.distance = 3
        assert(Set(search("", distanceRange).map(\.id)) == ["holt", "waffles", "pancakes"])
        assert(distanceRange.count == 1)
        distanceRange.distance = 10
        assert(distanceRange.count == 1)
        filter.minimumPrice = 15
        assert(search("", filter).isEmpty)
        filter = OfferFilters(); filter.endingToday = true
        assert(search("", filter).map(\.id) == ["pancakes"])
        filter = OfferFilters(); filter.rating = 4.8
        assert(Set(search("", filter).map(\.id)) == ["nawa", "massage"])
        assert(search(sort: .price).first?.id == "holt")
        assert(search(sort: .discount).first?.id == "massage")
        assert(search(sort: .nearest).first?.id == "grill")
        assert(OfferFilters().count == 0)
        let english = HomeLocalization(language: "en")
        let arabic = HomeLocalization(language: "ar")
        assert(english.number(1234) == "1234")
        assert(arabic.number(1234) == "١٢٣٤")
        assert(english.number(4.8, decimals: 1) == "4.8")
        assert(arabic.number(4.8, decimals: 1) == "٤٫٨")
        assert(english.percent(50).contains("50%"))
        assert(arabic.percent(50).contains("٥٠"))
        assert(HomeLocalization.priceInput("١٢٫٥") == 12.5)
        assert(HomeLocalization.priceInput("۱۲.۵") == 12.5)
        assert(HomeLocalization.priceInput("12.5") == 12.5)
        assert(HomeLocalization.priceInput(arabic.number(1234)) == 1234)
        assert(HomeLocalization.priceInput("invalid") == nil)
        assert(HomeLocalization.priceInput("nan") == nil)
        func priceRange(_ minimum: String, _ maximum: String) -> HomePriceRangeInput {
            HomePriceRangeInput(minimumText: minimum, maximumText: maximum)
        }
        assert(priceRange("", "").isValid)
        assert(priceRange("700", "").isValid && priceRange("700", "").maximum == nil)
        assert(priceRange("", "٥٠٠").isValid && priceRange("", "٥٠٠").maximum == 500)
        assert(priceRange("٢٠٫٥", "100").isValid)
        assert(!priceRange("100", "20").isValid)
        assert(!priceRange("-1", "").isValid && !priceRange("", "oops").isValid)
        var openPriceRange = OfferFilters()
        openPriceRange.minimumPrice = 700
        let expensive = HomeOffer(id: "expensive", merchant: "", title: "", category: .cafes, asset: "",
                                  price: 800, originalPrice: 800, distance: 1, rating: 5, discount: 0, searchTerms: "")
        assert(OfferSearch.results(in: [expensive], query: "", category: .all, filters: openPriceRange, sort: .nearest).count == 1)
        openPriceRange = OfferFilters(); openPriceRange.maximumPrice = 500; openPriceRange.hasMaximumPrice = true
        assert(openPriceRange.count == 1)
        print("PASS: bilingual catalog search, combined filters, sorting, empty results and decimal localization")
    }
}
