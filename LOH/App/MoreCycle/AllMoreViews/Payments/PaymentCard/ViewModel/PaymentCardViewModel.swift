import Foundation
import Combine

@MainActor
final class PaymentCardViewModel: ObservableObject {
    @Published private(set) var cards: [AccountCard] = []
    @Published private(set) var cardsLoaded = false
    @Published private(set) var cardsError: String?
    let requests: AccountRequestController

    init(requests: AccountRequestController) { self.requests = requests }

    func loadCards() async {
        guard !requests.busy else { return }
        cardsError = nil
        let loaded = await requests.run { token, generation in
            let list: AccountCardList = try await requests.client.data(
                from: PaymentEndpoints.list(token: token), language: requests.language)
            guard Set(list.cards.map(\.id)).count == list.cards.count else { throw APIError.invalidResponse }
            try requests.check(token, generation)
            cards = list.cards; cardsLoaded = true
        }
        if !loaded { cardsError = requests.error }
    }
    func addCard(name: String, number: String, expiry: String, cvv: String, isDefault: Bool) async -> Bool {
        let input = PaymentCardInput(name: name, number: number, expiry: expiry, cvv: cvv, isDefault: isDefault)
        guard input.isValid else { requests.error = "payments.invalidDetails".localized; return false }
        let saved = await requests.run { token, generation in
            try await requests.client.perform(
                PaymentEndpoints.add(fields: input.fields, token: token), language: requests.language)
            try requests.check(token, generation)
        }
        if saved { await loadCards() }
        return saved
    }
    func setDefaultCard(_ card: AccountCard, name: String, number: String, expiry: String, cvv: String) async -> Bool {
        let input = PaymentCardInput(name: name, number: number, expiry: expiry, cvv: cvv, isDefault: true)
        guard input.isValid, String(input.number.suffix(4)) == card.lastFour else {
            requests.error = "payments.invalidDetails".localized; return false
        }
        let saved = await requests.run { token, generation in
            try await requests.client.perform(
                PaymentEndpoints.setDefault(id: card.id, fields: input.fields, token: token), language: requests.language)
            try requests.check(token, generation)
            for index in cards.indices { cards[index].isDefault = cards[index].id == card.id }
        }
        if saved { await loadCards() }
        return saved
    }
    func setDefaultCard(_ card: AccountCard) async -> Bool {
        let saved = await requests.run { token, generation in
            try await requests.client.perform(
                PaymentEndpoints.setDefault(id: card.id, token: token), language: requests.language)
            try requests.check(token, generation)
            for index in cards.indices { cards[index].isDefault = cards[index].id == card.id }
        }
        if saved { await loadCards() }
        return saved
    }
    func removeCard(_ id: Int) async -> Bool {
        let saved = await requests.run { token, generation in
            try await requests.client.perform(
                PaymentEndpoints.delete(id: id, token: token), language: requests.language)
            try requests.check(token, generation)
            cards.removeAll { $0.id == id }
        }
        if saved { await loadCards() }
        return saved
    }
    func renameCard(_ id: Int, name: String) async -> Bool {
        let name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty, name.count <= 100 else { requests.error = "payments.invalidName".localized; return false }
        let saved = await requests.run { token, generation in
            try await requests.client.perform(
                PaymentEndpoints.rename(id: id, name: name, token: token), language: requests.language)
            try requests.check(token, generation)
            if let index = cards.firstIndex(where: { $0.id == id }) { cards[index].nickname = name }
        }
        if saved { await loadCards() }
        return saved
    }

    func resetSession() {
        cards = []; cardsLoaded = false; cardsError = nil
    }
}
