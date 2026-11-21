import Foundation

@MainActor enum PaymentTests {
    static func run(service: LOHAccountService, session: AuthSession) async throws {
        checkLiveInput()
        await checkCardNumberContract(service: service, session: session)
        let requests = AccountRequestController(service: service, session: session)
        let model = PaymentCardViewModel(requests: requests)
        let invalidForm = AddPaymentCardViewModel()
        invalidForm.form = AddPaymentCardForm(name: "Daily", number: "1234", expiry: "13/99", cvv: "1")
        precondition(invalidForm.canSubmit && !invalidForm.valid)
        precondition(invalidForm.validationMessage(for: .number) == nil)
        let submittedInvalid = await invalidForm.submit(using: model)
        precondition(!submittedInvalid && invalidForm.validationMessage(for: .number) != nil)
        precondition(invalidForm.validationMessage(for: .expiry) != nil && invalidForm.validationMessage(for: .cvv) != nil)
        invalidForm.updateNumber("4242424242424242"); invalidForm.updateExpiry("1299"); invalidForm.updateCVV("123")
        precondition(invalidForm.canSubmit && invalidForm.valid)
        precondition(invalidForm.validationMessage(for: .number) == nil && invalidForm.validationMessage(for: .expiry) == nil && invalidForm.validationMessage(for: .cvv) == nil)
        var records: [[String: Any]] = [
            ["id": 42, "last_four": "4242", "brand": "visa", "holder_name": "Daily", "expiry": "12/99", "is_default": false]
        ]
        var calls: [String] = []
        var failNextList = false
        AccountMock.handler = { request in
            let path = request.url!.lastPathComponent
            calls.append(request.httpMethod! + " " + request.url!.path)
            precondition(request.value(forHTTPHeaderField: "Authorization") == "Bearer test")
            precondition(request.value(forHTTPHeaderField: "lang") == "en")
            let body = AccountTests.body(request)
            if request.httpMethod == "GET" {
                precondition(path == "payment-cards" && request.url!.query == nil && body.isEmpty)
                if failNextList { failNextList = false; return (503, #"{"key":"fail","msg":"Refresh unavailable"}"#) }
                return (200, String(decoding: try JSONSerialization.data(withJSONObject: ["key": "success", "data": records]), as: UTF8.self))
            }
            switch path {
            case "add-payment-cards", "set-default":
                precondition(request.httpMethod == "POST")
                precondition(request.value(forHTTPHeaderField: "Content-Type")?.hasPrefix("multipart/form-data;") == true)
                for (key, value) in [("holder_name", "Daily"), ("card_number", "4242424242424242"), ("expiry", "12/99"), ("cvv", "123"), ("is_default", "1")] {
                    precondition(body.contains("name=\"\(key)\"\r\n\r\n\(value)\r\n"))
                }
                precondition(body.components(separatedBy: "Content-Disposition:").count == 6)
                if path == "set-default" {
                    precondition(request.url!.path == "/api/payment-cards/42/set-default" && request.url!.query == "_method=patch")
                    for i in records.indices { records[i]["is_default"] = records[i]["id"] as? Int == 42 }
                } else {
                    precondition(request.url!.query == nil)
                    records[0]["is_default"] = false
                    records.append(["id": 88, "last_four": "4242", "brand": "visa", "holder_name": "Daily", "expiry": "12/99", "is_default": true])
                }
            case "rename":
                precondition(request.httpMethod == "POST" && request.url!.path == "/api/payment-cards/42/rename")
                precondition(request.url!.query == "_method=patch")
                precondition(body.contains("name=\"holder_name\"\r\n\r\nTravel\r\n"))
                precondition(body.components(separatedBy: "Content-Disposition:").count == 2)
                records[0]["holder_name"] = "Travel"
            case "88":
                precondition(request.httpMethod == "DELETE" && request.url!.path == "/api/delete-payment-cards/88")
                precondition(request.url!.query == nil && body.isEmpty)
                records.removeAll { $0["id"] as? Int == 88 }
            default: preconditionFailure("Unexpected payment route")
            }
            return (200, #"{"key":"success"}"#)
        }
        await model.loadCards()
        precondition(model.cardsLoaded && model.cards.count == 1 && model.cardsError == nil)
        let addForm = AddPaymentCardViewModel()
        addForm.form = AddPaymentCardForm(name: " Daily ", number: "٤٢٤٢ ٤٢٤٢ ٤٢٤٢ ٤٢٤٢", expiry: "١٢/٩٩", cvv: "١٢٣", isDefault: true)
        precondition(addForm.valid)
        let added = await addForm.submit(using: model)
        precondition(addForm.form.number.isEmpty && addForm.form.cvv.isEmpty)
        precondition(added && model.cards.count == 2 && model.cards[1].isDefault)
        let defaultForm = AddPaymentCardViewModel(defaultCard: model.cards[0])
        precondition(defaultForm.form.name == "Daily" && defaultForm.form.expiry == "12/99" && !defaultForm.valid)
        defaultForm.form.number = "4242424242424242"; defaultForm.form.cvv = "123"
        let changed = await defaultForm.submit(using: model)
        precondition(changed && model.cards[0].isDefault && !model.cards[1].isDefault)
        let renamed = await model.renameCard(42, name: " Travel ")
        precondition(renamed && model.cards[0].nickname == "Travel")
        failNextList = true
        let removed = await model.removeCard(88)
        precondition(removed && model.cards.count == 1 && model.cardsError == "Refresh unavailable")
        await model.loadCards()
        precondition(model.cardsError == nil && model.cards.count == 1)
        precondition(calls.contains("POST /api/add-payment-cards") && calls.contains("POST /api/payment-cards/42/set-default") && calls.contains("POST /api/payment-cards/42/rename") && calls.contains("DELETE /api/delete-payment-cards/88"))
        let count = calls.count
        let invalid = await model.addCard(name: String(repeating: "a", count: 101), number: "4242424242424242", expiry: "12/99", cvv: "123", isDefault: true)
        let wrongCard = await model.setDefaultCard(model.cards[0], name: "Daily", number: "5555555555554444", expiry: "12/99", cvv: "123")
        precondition(!invalid && !wrongCard && calls.count == count)
        AccountMock.handler = { _ in (422, #"{"key":"fail","msg":"Card rejected"}"#) }
        let rejected = await model.removeCard(42)
        precondition(!rejected && model.cards.count == 1 && requests.error == "Card rejected")
        let failedModel = PaymentCardViewModel(requests: AccountRequestController(service: service, session: session))
        await failedModel.loadCards()
        precondition(!failedModel.cardsLoaded && failedModel.cardsError == "Card rejected")
        AccountMock.handler = { _ in (200, #"{"key":"success","data":[{"id":42,"last_four":"4242","is_default":true},{"id":42,"last_four":"4242","is_default":false}]}"#) }
        await model.loadCards()
        precondition(model.cards.count == 1 && model.cardsError != nil)
        model.resetSession()
        precondition(model.cards.isEmpty && !model.cardsLoaded && model.cardsError == nil)
        print("PASS: all five collection payment endpoints, multipart fields, default-card confirmation, failed refresh retry, rejection, duplicate IDs and session cleanup")
    }

    private static func checkCardNumberContract(service: LOHAccountService, session: AuthSession) async {
        // The collection specifies digits_between:13,19 without a checksum restriction.
        for (length, expected) in [(0, false), (12, false), (13, true), (16, true), (19, true), (20, false)] {
            let input = PaymentCardInput(name: "Daily", number: String(repeating: "4", count: length),
                                         expiry: "12/99", cvv: "123", isDefault: true)
            precondition(input.isValid == expected, "Card validation must match the collection's digit limits")
        }
        let requests = AccountRequestController(service: service, session: session)
        let cards = PaymentCardViewModel(requests: requests)
        let form = AddPaymentCardViewModel()
        var calls: [String] = []
        var reject = false
        AccountMock.handler = { request in
            calls.append(request.httpMethod! + " " + request.url!.path)
            if request.httpMethod == "GET" {
                precondition(request.url!.path == "/api/payment-cards")
                return (200, #"{"key":"success","data":[]}"#)
            }
            precondition(request.httpMethod == "POST" && request.url!.path == "/api/add-payment-cards")
            precondition(AccountTests.body(request).contains("name=\"card_number\"\r\n\r\n4242424242424243\r\n"))
            return reject ? (422, #"{"key":"fail","msg":"Card rejected"}"#) : (200, #"{"key":"success"}"#)
        }
        form.form = AddPaymentCardForm(name: "Daily", number: "424242424242", expiry: "12/99", cvv: "123")
        let invalid = await form.submit(using: cards)
        precondition(!invalid && calls.isEmpty && form.validationMessage(for: .number) != nil)
        // This 16-digit value failed the old Luhn check despite satisfying the API contract.
        form.updateNumber("٤٢٤٢ ٤٢٤٢ ٤٢٤٢ ٤٢٤٣")
        precondition(form.valid && form.validationMessage(for: .number) == nil)
        let saved = await form.submit(using: cards)
        precondition(saved && calls == ["POST /api/add-payment-cards", "GET /api/payment-cards"])
        reject = true
        form.form = AddPaymentCardForm(name: "Daily", number: "4242 4242 4242 4243", expiry: "12/99", cvv: "123")
        let rejected = await form.submit(using: cards)
        precondition(!rejected && calls.count == 3 && requests.error == "Card rejected")
        precondition(form.validationMessage(for: .number) == nil)
        print("PASS: collection card-number length limits, 16-digit submission, normalized digits and server rejection")
    }

    private static func checkLiveInput() {
        let form = AddPaymentCardViewModel()
        form.form.name = "Daily"
        for (typed, displayed) in [("4", "4"), ("42", "42"), ("424", "424"), ("4242", "4242"), ("42424", "4242 4")] {
            form.updateNumber(typed)
            precondition(form.form.number == displayed)
        }
        form.updateNumber(String(form.form.number.dropLast()))
        precondition(form.form.number == "4242")
        for (typed, displayed) in [("1", "1"), ("12", "12"), ("129", "12/9"), ("12/99", "12/99")] {
            form.updateExpiry(typed)
            precondition(form.form.expiry == displayed)
        }
        form.updateExpiry(String(form.form.expiry.dropLast()))
        precondition(form.form.expiry == "12/9")
        for typed in ["1", "12", "123", "1234"] {
            form.updateCVV(typed)
            precondition(form.form.cvv == typed)
        }
        form.updateNumber("٤٢٤٢ ٤٢٤٢ ٤٢٤٢ ٤٢٤٢")
        form.updateExpiry("١٢/٩٩")
        form.updateCVV("١٢٣")
        precondition(form.form.number == "4242 4242 4242 4242" && form.form.expiry == "12/99" && form.form.cvv == "123")
        precondition(form.valid && form.form.name == "Daily")
        form.updateNumber(String(repeating: "4", count: 25))
        form.updateExpiry("12/9999")
        form.updateCVV("123456")
        precondition(AccountValidation.digits(form.form.number).count == 19 && form.form.expiry == "12/99" && form.form.cvv == "1234")
        form.updateNumber(""); form.updateExpiry(""); form.updateCVV("")
        precondition(form.form.number.isEmpty && form.form.expiry.isEmpty && form.form.cvv.isEmpty && !form.valid)
        print("PASS: immediate payment form updates, formatting while typing, backspace, Unicode paste, length limits and validation")
    }
}
