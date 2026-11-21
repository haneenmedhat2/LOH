import Foundation

struct AccountProfile {
    var name = ""
    var email = ""
    var phone = ""
    var birthday = Calendar.current.date(from: DateComponents(year: 1990, month: 5, day: 15)) ?? Date()
    var gender = "male"
    var city = "Riyadh"
    var cityID: Int?
    var imageURL: String?
    var hasBirthday = false
}
