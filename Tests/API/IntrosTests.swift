import Foundation

@MainActor enum IntrosTests {
    static func run(client: APIClient) async throws {
        precondition(APIEnvironment.current.baseURL.absoluteString == "https://upgrade.loh.com.sa/api/")
        let service = LOHIntrosService(client: client)
        MockProtocol.handler = { request in
            precondition(request.httpMethod == "GET" && request.url!.path == "/api/intros")
            precondition(URLComponents(url: request.url!, resolvingAgainstBaseURL: false)?.queryItems == [.init(name: "type", value: "user")])
            precondition(request.value(forHTTPHeaderField: "lang") == "ar")
            precondition(request.value(forHTTPHeaderField: "Authorization") == nil)
            return (200, #"{"key":"success","data":[{"id":5,"type":"user","title":"عنوان","description":"وصف","image":"https://example.invalid/intro.jpg","tags":[{"id":"1","name":"Tag","icon":"https://example.invalid/tag.png"}]},{"id":"2","title":"Second","description":null,"image":null}]}"#)
        }
        let model = OnboardingViewModel(service: service)
        await model.load(language: "ar")
        precondition(model.pages.map(\.id) == [5, 2] && model.selectedPage == 0)
        precondition(model.pages[0].title == "عنوان" && model.pages[0].imageURL != nil)
        precondition(model.pages[0].type == "user" && model.pages[0].tags.first?.id == 1)
        precondition(model.pages[0].tags.first?.name == "Tag" && model.pages[0].tags.first?.icon == "https://example.invalid/tag.png")
        precondition(model.pages[1].type == nil && model.pages[1].tags.isEmpty)
        precondition(model.pages[1].message.isEmpty && model.pages[1].imageURL == nil)
        precondition(!model.advance() && model.selectedPage == 1 && model.isLastPage)
        precondition(model.advance() && model.selectedPage == 1)
        MockProtocol.handler = { request in
            precondition(request.value(forHTTPHeaderField: "lang") == "en")
            return (500, #"{"key":"exception","msg":"Retry later"}"#)
        }
        await model.load(language: "en")
        precondition(model.errorMessage == "Retry later" && model.pages.isEmpty && !model.isLoading)
        precondition(!model.advance())
        MockProtocol.handler = { _ in (200, #"{"key":"success","data":[]}"#) }
        await model.load(language: "en")
        precondition(model.errorMessage == nil && model.pages.isEmpty && model.advance())
        MockProtocol.handler = { _ in (200, #"{"key":"success","data":[{"id":1,"title":"One"},{"id":1,"title":"Duplicate"}]}"#) }
        await model.load(language: "en")
        precondition(model.errorMessage != nil && model.pages.isEmpty)
        print("PASS: upgrade base URL, intros request/decoding, nonsequential IDs, paging, language reload, retry, empty and duplicate results")
    }
}
