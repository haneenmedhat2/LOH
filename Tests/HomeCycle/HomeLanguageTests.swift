import Foundation
import Combine

@main
struct HomeLanguageTests {
    static func main() {
        let defaults = UserDefaults.standard
        let previousSelection = defaults.object(forKey: "selectedLanguage")
        let previousAppleLanguages = defaults.object(forKey: "AppleLanguages")
        defer {
            defaults.set(previousSelection, forKey: "selectedLanguage")
            defaults.set(previousAppleLanguages, forKey: "AppleLanguages")
        }
        let bundle = Bundle(path: CommandLine.arguments[1])!
        let language = AppLanguageManager.shared
        var changes = [String]()
        let subscription = language.$selectedLanguage.sink { changes.append($0) }
        for code in ["ar", "en", "ar", "en"] {
            language.setLanguage(code)
            let localization = HomeLocalization(language: language.selectedLanguage)
            assert(localization.text("home", bundle: bundle) == (code == "ar" ? "الرئيسية" : "Home"))
            assert(localization.text("Nawa Café", bundle: bundle) == (code == "ar" ? "نواة كافيه" : "Nawa Café"))
            assert(AppLanguageManager.currentLanguage() == code)
            assert(AppLanguageManager.isRTL() == (code == "ar"))
            assert(language.isRTL == (code == "ar"))
            assert(defaults.string(forKey: "selectedLanguage") == code)
            assert(defaults.stringArray(forKey: "AppleLanguages")?.first == code)
            let path = bundle.path(forResource: code, ofType: "lproj")!
            let table = NSDictionary(contentsOfFile: path + "/Localizable.strings") as! [String: String]
            for (key, expected) in table where key.hasPrefix("home.") {
                assert(localization.text(String(key.dropFirst(5)), bundle: bundle) == expected, key)
            }
            let greeting = String(format: localization.text("greetingFormat", bundle: bundle), "Test")
            assert(greeting.contains("Test") && !greeting.contains("greetingFormat"))
            let money = String(format: localization.text("moneyFormat", bundle: bundle), "8")
            assert(money == (code == "ar" ? "8 ر.س" : "8 SAR"))
            for offer in HomeOffer.samples {
                assert(localization.text(offer.title, bundle: bundle) != offer.title)
                if code == "ar" { assert(localization.text(offer.merchant, bundle: bundle) != offer.merchant) }
            }
            for key in OfferCategory.allCases.map(\.rawValue) + OfferCity.allCases.map(\.rawValue) + OfferSort.allCases.map(\.rawValue) {
                assert(localization.text(key, bundle: bundle) != key)
            }
        }
        AppLanguageManager.setAppLanguage(lang: "ar-SA")
        assert(language.selectedLanguage == "ar")
        assert(AppLanguageManager().selectedLanguage == "ar")
        language.toggleLanguage()
        assert(language.selectedLanguage == "en")
        assert(changes.suffix(6) == ["ar", "en", "ar", "en", "ar", "en"])
        // iOS Settings changes AppleLanguages while the app's old cache remains English.
        defaults.set(["ar-SA", "en"], forKey: "AppleLanguages")
        language.refreshFromSystem()
        assert(language.selectedLanguage == "ar" && language.isRTL)
        assert(defaults.string(forKey: "selectedLanguage") == "ar")
        assert(defaults.stringArray(forKey: "AppleLanguages") == ["ar-SA", "en"])
        let publishedCount = changes.count
        language.refreshFromSystem()
        assert(changes.count == publishedCount)
        defaults.set("en", forKey: "selectedLanguage")
        assert(AppLanguageManager().selectedLanguage == "ar")
        assert(defaults.stringArray(forKey: "AppleLanguages") == ["ar-SA", "en"])
        defaults.set(["fr-FR", "en-GB", "ar"], forKey: "AppleLanguages")
        language.refreshFromSystem()
        assert(language.selectedLanguage == "en" && !language.isRTL)
        assert(defaults.string(forKey: "selectedLanguage") == "en")
        defaults.set(["ar_EG"], forKey: "AppleLanguages")
        language.refreshFromSystem()
        assert(language.apiLanguage == "ar")
        defaults.set(["fr"], forKey: "AppleLanguages")
        language.refreshFromSystem()
        assert(language.selectedLanguage == "en")
        print("PASS: Settings preference overrides stale cache on launch/foreground, preserves preference list, updates RTL/API language and avoids duplicate updates")
        withExtendedLifetime(subscription) {}
        print("PASS: actual Arabic/English bundle lookups, all catalog items, observed language switching, persistence and legacy language API")
    }
}
