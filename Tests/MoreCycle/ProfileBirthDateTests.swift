import Foundation

enum ProfileBirthDateTests {
    static func run() {
        let expected = DateComponents(year: 2000, month: 5, day: 15)
        let calendar = Calendar(identifier: .gregorian)
        for input in ["15 مايو 2000", "١٥ مايو ٢٠٠٠", "15 May 2000", "2000-05-15", "2000-05-15T00:00:00Z"] {
            guard let date = AccountBirthDate.parse(input) else {
                preconditionFailure("Could not parse birthdate: \(input)")
            }
            let components = calendar.dateComponents([.year, .month, .day], from: date)
            precondition(components == expected)
            precondition(AccountBirthDate.apiFormatter.string(from: date) == "2000-05-15")
        }
        for input in [nil, "", "invalid", "2000-02-30", "30 فبراير 2000"] as [String?] {
            precondition(AccountBirthDate.parse(input) == nil)
        }
        precondition(AccountBirthDate.parse("29 فبراير 2000") != nil)
        print(
            "PASS: Arabic/English/ISO birthdates, Arabic digits, Gregorian picker dates, invalid dates and API round-trip"
        )
    }
}
