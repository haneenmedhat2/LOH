import Foundation

@MainActor
enum AccountSettingsTests {
    static func run(client: APIClient, session: AuthSession) async throws {
        let service = LOHAccountService(client: client)
        let account = MoreAccountStore(service: service, session: session)
        let join = AccountJoinViewModel(requests: account.requests)
        join.form.business = " Business "
        join.form.name = " Contact "
        join.form.email = " name@example.com "
        precondition(!join.canSubmit)
        for value in ["5", "55", "555", "5556", "55566", "555666", "5556662", "55566622", "555666222"] {
            join.updatePhone(value)
            precondition(join.form.phone == value && join.canSubmit)
        }
        precondition(join.form.valid) // The collection's nine-digit example is valid.
        join.updatePhone("٠٥٥٥ ٦٦٦ ٢٢٢")
        precondition(join.form.phone == "055566622" && join.form.valid)
        join.updatePhone("۰۵۵۵۶۶۶۲۲۲")
        precondition(join.form.phone == "055566622")
        join.updatePhone("055566622")
        precondition(join.form.phone == "055566622" && join.form.valid)
        join.updatePhone("055566622233")
        precondition(join.form.phone == "055566622" && join.form.valid)
        precondition(AccountValidation.phoneDigits("+٩٦٦ ٥٥١٢٣٤٥٦٧٨٩") == "966551234")
        for value in ["12345678", "1234567890", "12345678901", "12345678a", "123 456789"] {
            precondition(!AccountValidation.validPhone(value))
        }
        precondition(AccountValidation.validPhone("123456789"))
        join.updatePhone("12345678")
        AccountMock.handler = { _ in preconditionFailure("Invalid form must not reach the API") }
        await join.submit()
        precondition(join.validationMessage(for: .phone) == "accountJoin.invalidPhone")
        join.updatePhone("555666222")
        join.form.email = "invalid"
        await join.submit()
        precondition(join.validationMessage(for: .email) == "accountJoin.invalidEmail")
        join.form.email = " name@example.com "
        join.form.business = String(repeating: "a", count: 191)
        precondition(join.form.valid)
        join.form.business += "a"
        precondition(!join.form.valid)
        join.form.business = " Business "

        AccountMock.handler = { request in
            precondition(request.httpMethod == "POST" && request.url!.path == "/api/join-us")
            precondition(request.value(forHTTPHeaderField: "Authorization") == "Bearer test")
            let body = AccountTests.body(request)
            for (key, value) in [("company_name", "Business"), ("responsible_person_name", "Contact"),
                                 ("phone", "555666222"), ("email", "name@example.com")] {
                precondition(body.contains("name=\"\(key)\"\r\n\r\n\(value)\r\n"))
            }
            return (200, #"{"key":"success","msg":"Join accepted"}"#)
        }
        await join.submit()
        precondition(join.submitted)

        let password = AccountPasswordViewModel(requests: account.requests)
        precondition(!AccountValidation.validPasswordChange(current: "12345", new: "654321", confirmation: "654321"))
        password.form = AccountPasswordForm(current: "current123", password: "updated456", confirmation: "updated456")
        var rejectPassword = true
        AccountMock.handler = { request in
            precondition(request.url!.path == "/api/update-password" && request.url!.query == "_method=patch" && request.httpMethod == "POST")
            precondition(request.value(forHTTPHeaderField: "Authorization") == "Bearer test")
            let body = AccountTests.body(request)
            precondition(body.contains("name=\"old_password\"\r\n\r\ncurrent123\r\n"))
            precondition(body.contains("name=\"password\"\r\n\r\nupdated456\r\n"))
            precondition(!body.contains("password_confirmation"))
            return rejectPassword ? (422, #"{"key":"fail","msg":"Wrong current password"}"#) : (200, #"{"key":"success","msg":"Password updated"}"#)
        }
        await password.submit()
        precondition(!password.completed && password.form.current == "current123" && account.requests.error == "Wrong current password")
        rejectPassword = false
        await password.submit()
        precondition(password.completed && password.form.current.isEmpty && password.form.password.isEmpty && password.form.confirmation.isEmpty)

        var rejectLanguage = false
        AccountMock.handler = { request in
            let code = request.value(forHTTPHeaderField: "lang")!
            precondition(["ar", "en"].contains(code))
            precondition(request.url!.path == "/api/change-lang" && request.url!.query == "lang=\(code)")
            precondition(request.httpMethod == "PATCH" && AccountTests.body(request).isEmpty)
            precondition(request.value(forHTTPHeaderField: "Authorization") == "Bearer test")
            return rejectLanguage ? (500, #"{"key":"fail","msg":"Language unavailable"}"#) : (200, #"{"key":"success","msg":"Language updated"}"#)
        }
        for code in ["ar", "en"] {
            let changed = await account.language.changeLanguage(code)
            precondition(changed && account.requests.error == nil)
        }
        rejectLanguage = true
        let changed = await account.language.changeLanguage("ar")
        precondition(!changed && !account.language.languageChangeConfirmed && account.requests.error == "Language unavailable")

        try await documents(service)
        print("PASS: Join live form state, Unicode phone digits, nine-digit contract, validation feedback, password update and language success/failure")
    }

    static func documents(_ service: LOHAccountService) async throws {
        let fixtures = URL(fileURLWithPath: #filePath).deletingLastPathComponent().appendingPathComponent("Fixtures")
        let about = try String(contentsOf: fixtures.appendingPathComponent("account-about-en.json"))
        let security = try String(contentsOf: fixtures.appendingPathComponent("account-security-ar.json"))
        precondition(AccountDocument.privacy.endpoint == .privacy && AccountDocument.terms.endpoint == .terms && AccountDocument.about.endpoint == .about)
        precondition(AccountSecurityContent().endpoint == .securityPrivacy)
        var reject = false, malformed = false, empty = false
        AccountMock.handler = { request in
            precondition(request.httpMethod == "GET" && request.url!.query == nil)
            precondition(request.value(forHTTPHeaderField: "Authorization") == nil)
            precondition(AccountTests.body(request).isEmpty)
            if reject { return (503, #"{"key":"fail","msg":"Document unavailable"}"#) }
            if malformed { return (200, #"{"key":"success","data":{"unexpected":"value"}}"#) }
            if empty { return (200, #"{"key":"success","data":""}"#) }
            switch request.url!.path {
            case "/api/about": return (200, about)
            case "/api/security-privacy": return (200, security)
            case "/api/privacy-page", "/api/terms-page":
                let title = request.value(forHTTPHeaderField: "lang") == "ar" ? "محتوى المستند" : "Document content"
                return (200, #"{"key":"success","data":{"header":{"title":"\#(title)","description":"Introduction","image":"","last_updated":"15 October 2026"},"sections":[{"id":1,"image":"","title":"First section","points":["First point","Second point"]}]}}"#)
            default: preconditionFailure("Unexpected public document endpoint")
            }
        }
        let model = AccountDocumentViewModel(service: service)
        await model.load(endpoint: .securityPrivacy, language: "ar")
        guard case .sections(let content) = model.content else { preconditionFailure("Structured security content must decode") }
        precondition(content.header?.title == "خصوصيتك وأمانك أولويتنا" && content.items.count == 4)
        precondition(content.items[0].title == "حماية البيانات" && content.items[0].imageURL == nil)
        precondition(content.footer?.title == "تجربة آمنة وموثوقة" && model.error == nil && !model.loading)
        await model.load(endpoint: .about, language: "en")
        guard case .sections(let aboutContent) = model.content else { preconditionFailure("Structured About content must decode") }
        precondition(aboutContent.header?.title == "About Last One Hour" && aboutContent.items.isEmpty && aboutContent.footer != nil)
        for endpoint in [AccountDocumentEndpoint.privacy, .terms] {
            for language in ["ar", "en"] {
                await model.load(endpoint: endpoint, language: language)
                guard case .sections(let page) = model.content else { preconditionFailure("Page sections must decode") }
                let expected = language == "ar" ? "محتوى المستند" : "Document content"
                precondition(page.header?.title == expected && page.header?.lastUpdated == "15 October 2026")
                precondition(page.sections.count == 1 && page.sections[0].points.count == 2 && model.error == nil)
            }
        }
        reject = true
        await model.load(endpoint: .about, language: "en")
        precondition(model.content == nil && model.error == "Document unavailable" && !model.loading)
        reject = false; malformed = true
        await model.load(endpoint: .about, language: "en")
        precondition(model.content == nil && model.error != nil)
        malformed = false; empty = true
        await model.load(endpoint: .about, language: "en")
        precondition(model.content?.isEmpty == true && model.error == nil)
        empty = false
        await model.load(endpoint: .about, language: "en")
        precondition(model.content?.isEmpty == false && model.error == nil)
        print("PASS: public privacy-page/terms-page/about/security routes, structured sections, language changes, errors and retries")
    }
}
