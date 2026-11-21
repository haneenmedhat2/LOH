import Foundation

enum AccountBirthDate {
    static var apiFormatter: DateFormatter {
        formatter(locale: "en_US_POSIX", format: "yyyy-MM-dd")
    }

    static func parse(_ value: String?) -> Date? {
        guard let value else { return nil }
        let normalized =
            value
            .filter { !$0.unicodeScalars.allSatisfy { CharacterSet.controlCharacters.contains($0) } }
            .map { character in
                character.wholeNumberValue.map(String.init) ?? String(character)
            }
            .joined()
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else { return nil }

        let isoDate = String(normalized.prefix(10))
        if let date = apiFormatter.date(from: isoDate), apiFormatter.string(from: date) == isoDate {
            return date
        }
        for locale in ["ar_SA", "en_US_POSIX"] {
            if let date = formatter(locale: locale, format: "d MMMM yyyy").date(from: normalized) {
                return date
            }
        }
        return nil
    }

    private static func formatter(locale: String, format: String) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: locale)
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateFormat = format
        formatter.isLenient = false
        return formatter
    }
}
