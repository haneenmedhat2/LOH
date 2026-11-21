import Foundation

struct AccountLanguageOption: Identifiable {
    let id: String
    let title: String
    let flag: String

    static let available = [
        AccountLanguageOption(id: "ar", title: "العربية", flag: "🇸🇦"),
        AccountLanguageOption(id: "en", title: "English", flag: "🇺🇸")
    ]
}
