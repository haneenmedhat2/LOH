import Foundation

struct RecoveryCodeModel {
    let phone: String
    let countryCode: String
    var formattedPhone: String { "+\(countryCode) \(phone)" }
}
