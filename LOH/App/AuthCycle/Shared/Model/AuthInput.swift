import Foundation

enum AuthInput {
    static func normalizedDigits(_ value: String, limit: Int = 15) -> String {
        String(value.compactMap { character -> Character? in
            guard let number = character.wholeNumberValue, (0...9).contains(number) else { return nil }
            return Character(String(number))
        }.prefix(limit))
    }
    static func validEmail(_ value: String) -> Bool {
        value.isEmpty || value.range(of: #"^[^\s@]+@[^\s@]+\.[^\s@]+$"#, options: .regularExpression) != nil
    }
}
