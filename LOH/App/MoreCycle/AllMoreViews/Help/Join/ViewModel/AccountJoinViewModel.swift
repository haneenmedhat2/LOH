import Foundation
import Combine

@MainActor
final class AccountJoinViewModel: ObservableObject {

    @Published var form = AccountJoinForm()
    @Published private(set) var submitted = false
    @Published private(set) var attemptedSubmission = false
    var canSubmit: Bool { form.isComplete && !submitted }

    func updatePhone(_ value: String) {
        let digits = AccountValidation.phoneDigits(value)
        if form.phone != digits { form.phone = digits }
    }

    func validationMessage(for field: AccountJoinField) -> String? {
        attemptedSubmission ? form.validationKey(for: field)?.localized : nil
    }

    func submit() async {
        attemptedSubmission = true
        guard form.valid else { return }
        submitted = await join(business: form.business, name: form.name, email: form.email, phone: form.phone, notes: form.details)
    }

    private let requests: AccountRequestController

    init(requests: AccountRequestController) { self.requests = requests }

    private func join(business: String, name: String, email: String, phone: String, notes: String) async -> Bool {
        await requests.run { token, _ in
            try await requests.client.perform(AccountEndpoints.join(fields: [
                ("company_name", business.trimmingCharacters(in: .whitespacesAndNewlines)),
                ("responsible_person_name", name.trimmingCharacters(in: .whitespacesAndNewlines)),
                ("email", email.trimmingCharacters(in: .whitespacesAndNewlines)),
                ("phone", AccountValidation.phoneDigits(phone)), ("notes", notes)], token: token),
                language: requests.language)
        }
    }

}
