import Foundation

enum AccountJoinField { case business, name, phone, email }

struct AccountJoinForm {
    var business = ""
    var name = ""
    var phone = ""
    var email = ""
    var details = ""

    var normalizedPhone: String { AccountValidation.phoneDigits(phone) }
    var isComplete: Bool {
        [business, name, phone, email].allSatisfy { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }
    var valid: Bool {
        [.business, .name, .phone, .email].allSatisfy { validationKey(for: $0) == nil } && details.count <= 255
    }
    func validationKey(for field: AccountJoinField) -> String? {
        switch field {
        case .business, .name:
            let value = (field == .business ? business : name).trimmingCharacters(in: .whitespacesAndNewlines)
            return value.isEmpty || value.count > 191 ? "accountJoin.invalidName" : nil
        case .phone:
            return AccountValidation.validPhone(phone) ? nil : "accountJoin.invalidPhone"
        case .email:
            let value = email.trimmingCharacters(in: .whitespacesAndNewlines)
            return value.isEmpty || value.count > 191 || !AccountValidation.validEmail(value) ? "accountJoin.invalidEmail" : nil
        }
    }
}
