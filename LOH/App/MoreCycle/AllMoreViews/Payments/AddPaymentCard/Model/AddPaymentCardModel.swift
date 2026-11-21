import Foundation

enum AddPaymentCardField: Hashable {
    case name, number, expiry, cvv

    func formatted(_ value: String) -> String {
        switch self {
        case .name: return value
        case .number:
            let digits = String(AccountValidation.digits(value).prefix(19))
            return stride(from: 0, to: digits.count, by: 4).map { String(digits.dropFirst($0).prefix(4)) }.joined(separator: " ")
        case .expiry:
            let digits = String(AccountValidation.digits(value).prefix(4))
            return digits.count > 2 ? String(digits.prefix(2)) + "/" + digits.dropFirst(2) : digits
        case .cvv: return String(AccountValidation.digits(value).prefix(4))
        }
    }
}

struct PaymentCardInput {
    let name: String
    let number: String
    let expiry: String
    let cvv: String
    let isDefault: Bool
    init(name: String, number: String, expiry: String, cvv: String, isDefault: Bool) {
        self.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        self.number = AccountValidation.digits(number)
        let digits = AccountValidation.digits(expiry)
        self.expiry = digits.count == 4 ? String(digits.prefix(2)) + "/" + digits.suffix(2) : expiry
        self.cvv = AccountValidation.digits(cvv)
        self.isDefault = isDefault
    }
    var isValid: Bool {
        !name.isEmpty && name.count <= 100 && AccountValidation.validCard(number) &&
        AccountValidation.validExpiry(expiry) && (3...4).contains(cvv.count)
    }
    var fields: [(String, String)] {
        [("holder_name", name), ("card_number", number), ("expiry", expiry),
         ("cvv", cvv), ("is_default", isDefault ? "1" : "0")]
    }
}

struct AddPaymentCardForm {
    var name = ""
    var number = ""
    var expiry = ""
    var cvv = ""
    var isDefault = true

    var input: PaymentCardInput {
        PaymentCardInput(name: name, number: number, expiry: expiry, cvv: cvv, isDefault: isDefault)
    }
}
