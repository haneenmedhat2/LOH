import Foundation

/// Explicitly uses the app language, independently of the device region.
struct HomeLocalization {
    let language: String
    var locale: Locale { Locale(identifier: language.hasPrefix("ar") ? "ar_SA" : "en_SA") }

    func text(_ key: String, bundle: Bundle = .main) -> String {
        let code = language.lowercased().hasPrefix("ar") ? "ar" : "en"
        guard let path = bundle.path(forResource: code, ofType: "lproj"),
              let localizedBundle = Bundle(path: path) else { return key }
        return localizedBundle.localizedString(forKey: "home." + key, value: key, table: "Localizable")
    }

    func number(_ value: Double, decimals: Int = 0) -> String {
        let formatter = NumberFormatter()
        formatter.locale = locale
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = false
        formatter.minimumFractionDigits = decimals
        formatter.maximumFractionDigits = decimals
        return formatter.string(from: NSNumber(value: value)) ?? String(value)
    }

    func percent(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.locale = locale
        formatter.numberStyle = .percent
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: Double(value) / 100)) ?? number(Double(value))
    }

    static func priceInput(_ value: String) -> Double? {
        let normalized = value.trimmingCharacters(in: .whitespacesAndNewlines).map { character -> String in
            if let digit = character.wholeNumberValue { return String(digit) }
            return character == "٫" ? "." : String(character)
        }.joined()
        guard let result = Double(normalized), result.isFinite else { return nil }
        return result
    }
}

/// Parses optional price bounds without treating an empty field as a price.
struct HomePriceRangeInput {
    let minimumText: String
    let maximumText: String

    var minimum: Double? { HomeLocalization.priceInput(minimumText) }
    var maximum: Double? { HomeLocalization.priceInput(maximumText) }
    var hasMinimum: Bool { !minimumText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    var hasMaximum: Bool { !maximumText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    var isValid: Bool {
        if hasMinimum && (minimum.map { $0 >= 0 } != true) { return false }
        if hasMaximum && (maximum.map { $0 >= 0 } != true) { return false }
        if let minimum, let maximum, minimum > maximum { return false }
        return true
    }
}
