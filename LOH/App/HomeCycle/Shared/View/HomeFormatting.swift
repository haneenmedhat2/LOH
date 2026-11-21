import SwiftUI
import UIKit

func homeText(_ key: String) -> String {
    HomeLocalization(language: AppLanguageManager.shared.selectedLanguage).text(key)
}
private var homeLocalization: HomeLocalization {
    HomeLocalization(language: AppLanguageManager.shared.apiLanguage)
}
func homeNumber(_ value: Int) -> String {
    homeLocalization.number(Double(value))
}
func homeNumber(_ value: Double, decimals: Int = 1) -> String {
    homeLocalization.number(value, decimals: decimals)
}
func homePercent(_ value: Int) -> String {
    homeLocalization.percent(value)
}
func homeFormat(_ key: String, _ values: String...) -> String {
    String(format: homeText(key), locale: homeLocalization.locale, arguments: values)
}
func homeMoney(_ value: Double, currency: String? = nil) -> String {
    let number = homeNumber(value, decimals: value.rounded() == value ? 0 : 2)
    guard let currency, !currency.isEmpty else {
        return homeFormat("moneyFormat", number)
    }
    return "\(number) \(currency)"
}
func homeDistance(_ value: Double) -> String {
    value < 1
        ? homeFormat("metersFormat", homeNumber(Int((value * 1000).rounded())))
        : homeFormat("distanceFormat", homeNumber(value))
}
