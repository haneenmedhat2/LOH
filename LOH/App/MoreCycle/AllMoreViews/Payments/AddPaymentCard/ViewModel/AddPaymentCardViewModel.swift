import Foundation
import Combine

@MainActor
final class AddPaymentCardViewModel: ObservableObject {
    @Published var form = AddPaymentCardForm()
    @Published private(set) var attemptedSubmission = false
    let defaultCard: AccountCard?

    init(defaultCard: AccountCard? = nil) {
        self.defaultCard = defaultCard
        if let defaultCard {
            form.name = defaultCard.nickname
            form.expiry = defaultCard.expiry
        }
    }

    var valid: Bool {
        form.input.isValid && (defaultCard == nil || String(form.input.number.suffix(4)) == defaultCard?.lastFour)
    }

    var canSubmit: Bool {
        !form.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !form.number.isEmpty && !form.expiry.isEmpty && !form.cvv.isEmpty
    }

    func validationMessage(for field: AddPaymentCardField) -> String? {
        guard attemptedSubmission else { return nil }
        let input = form.input
        switch field {
        case .name:
            return input.name.isEmpty || input.name.count > 100 ? "payments.invalidName".localized : nil
        case .number:
            if !AccountValidation.validCard(input.number) { return "payments.invalidNumber".localized }
            if let defaultCard, String(input.number.suffix(4)) != defaultCard.lastFour {
                return String(format: "payments.cardMismatch".localized, defaultCard.lastFour)
            }
            return nil
        case .expiry:
            return AccountValidation.validExpiry(input.expiry) ? nil : "payments.invalidExpiry".localized
        case .cvv:
            return (3...4).contains(input.cvv.count) ? nil : "payments.invalidCVV".localized
        }
    }

    func submit(using cards: PaymentCardViewModel) async -> Bool {
        attemptedSubmission = true
        guard valid else { return false }
        let saved: Bool
        if let defaultCard {
            saved = await cards.setDefaultCard(defaultCard, name: form.name, number: form.number, expiry: form.expiry, cvv: form.cvv)
        } else {
            saved = await cards.addCard(name: form.name, number: form.number, expiry: form.expiry, cvv: form.cvv, isDefault: form.isDefault)
        }
        if saved { form = AddPaymentCardForm(); attemptedSubmission = false }
        return saved
    }

    func updateNumber(_ value: String) {
        let formatted = AddPaymentCardField.number.formatted(value)
        if form.number != formatted { form.number = formatted }
    }

    func updateExpiry(_ value: String) {
        let formatted = AddPaymentCardField.expiry.formatted(value)
        if form.expiry != formatted { form.expiry = formatted }
    }

    func updateCVV(_ value: String) {
        let digits = AddPaymentCardField.cvv.formatted(value)
        if form.cvv != digits { form.cvv = digits }
    }

    func clearSensitiveData() { form.number = ""; form.cvv = "" }
}
