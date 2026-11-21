import Foundation

/// Local catalog examples stay available without requesting a store for a sample ID.
enum HomeMerchantPreview {
    static func make(offer: HomeOffer, offers: [HomeOffer], language: String) -> HomeMerchant? {
        guard !offer.isRemote else { return nil }
        let localization = HomeLocalization(language: language)
        var merchant = HomeMerchant(id: 0, name: offer.merchant)
        merchant.cover = offer.merchant == "Nawa Café" ? "lohMerchantCover" : offer.asset
        merchant.image = offer.merchantImage
        merchant.isVerified = true
        merchant.storeType = localization.text(offer.category.rawValue)
        merchant.rating = offer.rating
        merchant.ratingCount = 328
        merchant.distance = .kilometers(offer.distance)
        merchant.address = localization.text("district")
        merchant.about = localization.text(offer.category == .cafes ? "merchantAbout" : "merchantGeneric")
        merchant.categories = [.init(id: 17, name: localization.text("all"))]
        merchant.offers = offers.filter { $0.merchant == offer.merchant }
        if merchant.offers.isEmpty { merchant.offers = [offer] }
        merchant.stats = .init(offersCount: merchant.offers.count, distance: merchant.distance, rating: merchant.rating)
        merchant.location = .init(address: merchant.address, distance: merchant.distance)
        return merchant
    }
}
