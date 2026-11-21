import Foundation

struct IntrosEndpoints {
    private init() {}
}

extension IntrosEndpoints {
    static
    func user() -> Endpoint<APIEnvelope<[OnboardingPage]>> {
        return Endpoint(
            path: "intros",
            queries: ["type": "user"]
        )
    }
}
