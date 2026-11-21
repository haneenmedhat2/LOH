import SwiftUI

/// Exact Figma exports, grouped to match Assets.xcassets/LOH.
/// See LOHAssetManifest.json for source nodes and dimensions.
enum LOHAsset: String, CaseIterable {
    case flowBack = "lohFlowBack"
    case paymentMore = "lohPaymentMore"
    case paymentForward = "lohPaymentForward"
    case paymentBlackCard = "lohPaymentBlackCard"
    case paymentGoldCard = "lohPaymentGoldCard"
    case paymentSecurity = "lohPaymentSecurity"
    case paymentDelete = "lohPaymentDelete"
    case paymentRename = "lohPaymentRename"
    case paymentDefault = "lohPaymentDefault"
    case paymentFormShield = "lohPaymentFormShield"
    case paymentFormPerson = "lohPaymentFormPerson"
    case paymentFormCard = "lohPaymentFormCard"
    case paymentFormCalendar = "lohPaymentFormCalendar"
    case paymentFormLock = "lohPaymentFormLock"
    case paymentFormDefault = "lohPaymentFormDefault"
    case paymentSaveLock = "lohPaymentSaveLock"
    case paymentFooterLock = "lohPaymentFooterLock"
    case paymentFormBrands = "lohPaymentFormBrands"
    case paymentDeleteIllustration = "lohPaymentDeleteIllustration"
    case paymentDeleteDecoration = "lohPaymentDeleteDecoration"
    case accountCamera = "lohAccountCamera"
    case accountCalendar = "lohAccountCalendar"
    case accountForward = "lohAccountForward"
    case accountMenuArrow = "lohAccountMenuArrow"
    case accountPayment = "lohAccountPayment"
    case accountNotification = "lohAccountNotification"
    case accountSupport = "lohAccountSupport"
    case accountJoin = "lohAccountJoin"
    case accountSettings = "lohAccountSettings"
    case accountLogout = "lohAccountLogout"
    case profileEdit = "lohProfileEdit"
    case profileMail = "lohProfileMail"
    case profileCalendar = "lohProfileCalendar"
    case profilePerson = "lohProfilePerson"
    case profilePin = "lohProfilePin"
    case profileDown = "lohProfileDown"
    case profilePhone = "lohProfilePhone"
    case profileCheck = "lohProfileCheck"
    case profileSuccess = "lohProfileSuccess"
    // MARK: - Brand
    case logo = "lohLogo"
    case splashBrandLogo = "lohSplashBrandLogo"

    // MARK: - TabBar
    case tabAccount = "lohTabAccount"
    case tabHome = "lohTabHome"
    case tabOffers = "lohTabOffers"
    case tabPurchases = "lohTabPurchases"

    // MARK: - Auth
    case authStepCheck = "lohAuthStepCheck"
    case authVerified = "lohAuthVerified"
    case authAvatar = "lohAuthAvatar"
    case authBell = "lohAuthBell"
    case authCelebrationCard = "lohAuthCelebrationCard"
    case eyeOff = "lohEyeOff"
    case lock = "lohLock"
    case otpIllustration = "lohOtpIllustration"
    case successIllustration = "lohSuccessIllustration"
    case locationIllustration = "lohLocationIllustration"

    // MARK: - Onboarding
    case onboardingDiscover = "lohOnboardingDiscover"
    case onboardingPayment = "lohOnboardingPayment"
    case onboardingRedeem = "lohOnboardingRedeem"

    // MARK: - Home
    case homeBanner = "lohHomeBanner"

    // MARK: - Categories
    case categoryAll = "lohCategoryAll"
    case categoryBurgerPhoto = "lohCategoryBurgerPhoto"
    case categoryCafe = "lohCategoryCafe"
    case categoryCoffeePhoto = "lohCategoryCoffeePhoto"
    case categoryEntertainment = "lohCategoryEntertainment"
    case categoryEntertainmentPhoto = "lohCategoryEntertainmentPhoto"
    case categoryRestaurant = "lohCategoryRestaurant"
    case categorySpa = "lohCategorySpa"
    case categorySpaPhoto = "lohCategorySpaPhoto"
    case categorySport = "lohCategorySport"

    // MARK: - Offers
    case offerBurgerMeal = "lohOfferBurgerMeal"
    case offerCookieCoffee = "lohOfferCookieCoffee"
    case offerDailyCoffee = "lohOfferDailyCoffee"
    case offerMassage = "lohOfferMassage"
    case offerPancakes = "lohOfferPancakes"

    // MARK: - Search
    case filter = "lohFilter"
    case search = "lohSearch"
    case searchCoffee = "lohSearchCoffee"
    case searchEspresso = "lohSearchEspresso"
    case searchLatte = "lohSearchLatte"
    case searchWaffles = "lohSearchWaffles"

    // MARK: - Merchant
    case merchant = "lohMerchant"
    case merchantCheesecake = "lohMerchantCheesecake"
    case merchantCover = "lohMerchantCover"
    case merchantLatte = "lohMerchantLatte"
    case merchantSuccessIllustration = "lohMerchantSuccessIllustration"

    // MARK: - Purchases
    case purchaseBurger = "lohPurchaseBurger"
    case purchaseCoffee = "lohPurchaseCoffee"
    case redeem = "lohRedeem"
    case ticket = "lohTicket"

    // MARK: - Payment
    case mada = "lohMada"
    case mastercard = "lohMastercard"
    case paymentCard = "lohPaymentCard"
    case visa = "lohVisa"
    case cashback = "lohCashback"

    // MARK: - Notifications
    case notification = "lohNotification"
    case notificationBurger = "lohNotificationBurger"
    case notificationCoffee = "lohNotificationCoffee"

    // MARK: - Favorites
    case favoriteBurger = "lohFavoriteBurger"
    case favoriteCinema = "lohFavoriteCinema"
    case favoriteSpa = "lohFavoriteSpa"

    // MARK: - More
    case ticketSuccess = "lohTicketSuccess"
    case accountDeleted = "lohAccountDeleted"
    case deleteVerification = "lohDeleteVerification"
    case edit = "lohEdit"
    case globe = "lohGlobe"
    case joinUs = "lohJoinUs"
    case logout = "lohLogout"
    case mail = "lohMail"
    case person = "lohPerson"
    case profilePlaceholder = "lohProfilePlaceholder"
    case security = "lohSecurity"
    case settings = "lohSettings"
    case support = "lohSupport"
    case terms = "lohTerms"

    // MARK: - Shared
    case back = "lohBack"
    case bolt = "lohBolt"
    case checkCircle = "lohCheckCircle"
    case chevronDown = "lohChevronDown"
    case pin = "lohPin"
    case refresh = "lohRefresh"
    case shield = "lohShield"
    case shieldCheck = "lohShieldCheck"
    case star = "lohStar"
    case tag = "lohTag"

    var image: Image { Image(rawValue) }
}
