import Foundation

enum AccountValidation {
    static func validPasswordChange(current: String, new: String, confirmation: String) -> Bool {
        !current.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        new.count >= 6 && new.count <= 100 && (6...100).contains(current.count) && !new.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        new != current && new == confirmation
    }

    static func cardBrand(_ value: String) -> String {
        let value = digits(value)
        if value.hasPrefix("4") { return "visa" }
        let prefix = Int(value.prefix(2)) ?? 0
        let bin = Int(value.prefix(4)) ?? 0
        if (51...55).contains(prefix) || (2221...2720).contains(bin) { return "mastercard" }
        return "card"
    }

    static func digits(_ text: String) -> String {
        text.compactMap { $0.wholeNumberValue.map(String.init) }.joined()
    }
    static func phoneDigits(_ text: String) -> String {
        String(digits(text).prefix(9))
    }
    static func validPhone(_ value: String) -> Bool {
        value.count == 9 && value == phoneDigits(value)
    }
    static func validCard(_ value: String) -> Bool {
        // Match the payment collection's digits_between:13,19 rule.
        (13...19).contains(digits(value).count)
    }
    static func validExpiry(_ value: String, now: Date = Date()) -> Bool {
        let digits = digits(value)
        guard digits.count == 4, let month = Int(digits.prefix(2)), let year = Int(digits.suffix(2)), (1...12).contains(month) else { return false }
        let current = Calendar.current.dateComponents([.year, .month], from: now)
        return 2000 + year > current.year! || (2000 + year == current.year! && month >= current.month!)
    }
    static func validPassword(_ value: String) -> Bool {
        value.count >= 6 && value.rangeOfCharacter(from: .uppercaseLetters) != nil && value.rangeOfCharacter(from: .decimalDigits) != nil
    }
    static func validEmail(_ value: String) -> Bool {
        value.isEmpty || value.range(of: #"^[^\s@]+@[^\s@]+\.[^\s@]+$"#, options: .regularExpression) != nil
    }
}
