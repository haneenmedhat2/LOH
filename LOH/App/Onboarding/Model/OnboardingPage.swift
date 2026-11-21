import Foundation

struct OnboardingPage: Decodable, Identifiable {
    let id: Int
    let title: String
    let message: String
    let image: String?
    let type: String?
    let tags: [OnboardingTag]

    enum CodingKeys: String, CodingKey { case id, title, image, type, tags; case message = "description" }
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        guard let id = container.flexibleInt(.id) else { throw APIError.invalidResponse }
        self.id = id
        title = try container.decode(String.self, forKey: .title)
        message = try container.decodeIfPresent(String.self, forKey: .message) ?? ""
        image = try container.decodeIfPresent(String.self, forKey: .image)
        type = try container.decodeIfPresent(String.self, forKey: .type)
        tags = try container.decodeIfPresent([OnboardingTag].self, forKey: .tags) ?? []
    }
    var imageURL: URL? {
        guard let image, let url = URL(string: image), url.scheme == "https" else { return nil }
        return url
    }
}

struct OnboardingTag: Decodable, Identifiable {
    let id: Int
    let name: String
    let icon: String?

    enum CodingKeys: String, CodingKey { case id, name, icon }
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        guard let id = container.flexibleInt(.id) else { throw APIError.invalidResponse }
        self.id = id
        name = try container.decode(String.self, forKey: .name)
        icon = try container.decodeIfPresent(String.self, forKey: .icon)
    }

    var iconURL: URL? {
        guard let icon, let url = URL(string: icon), url.scheme == "https" else { return nil }
        return url
    }
}
