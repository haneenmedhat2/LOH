import Foundation

enum AccountDocument: String, Hashable {
    case privacy, terms, about
    var endpoint: AccountDocumentEndpoint {
        switch self {
        case .privacy: return .privacy
        case .terms: return .terms
        case .about: return .about
        }
    }
}

enum AccountDocumentContent: Decodable, Equatable {
    case text(String)
    case sections(AccountDocumentSections)

    init(from decoder: Decoder) throws {
        if let text = try? decoder.singleValueContainer().decode(String.self) {
            self = .text(text)
        } else {
            self = .sections(try AccountDocumentSections(from: decoder))
        }
    }

    var isEmpty: Bool {
        switch self {
        case .text(let text): return text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .sections(let sections):
            return (sections.header?.isEmpty ?? true) && sections.items.allSatisfy(\.isEmpty)
                && sections.sections.allSatisfy(\.isEmpty) && (sections.footer?.isEmpty ?? true)
        }
    }
}

struct AccountDocumentSections: Decodable, Equatable {
    let header: AccountDocumentBlock?
    let items: [AccountDocumentBlock]
    let sections: [AccountDocumentPointSection]
    let footer: AccountDocumentBlock?
    private enum CodingKeys: String, CodingKey { case header, items, sections, footer }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        guard container.contains(.header) || container.contains(.items)
            || container.contains(.sections) || container.contains(.footer) else {
            throw APIError.invalidResponse
        }
        header = try container.decodeIfPresent(AccountDocumentBlock.self, forKey: .header)
        items = try container.decodeIfPresent([AccountDocumentBlock].self, forKey: .items) ?? []
        sections = try container.decodeIfPresent([AccountDocumentPointSection].self, forKey: .sections) ?? []
        footer = try container.decodeIfPresent(AccountDocumentBlock.self, forKey: .footer)
    }
}

struct AccountDocumentPointSection: Decodable, Equatable {
    let id: Int
    let title: String
    let image: String?
    let points: [String]

    var imageURL: URL? {
        guard let image, let url = URL(string: image), ["http", "https"].contains(url.scheme?.lowercased() ?? "") else { return nil }
        return url
    }
    var isEmpty: Bool { title.isEmpty && points.allSatisfy(\.isEmpty) && imageURL == nil }
}

struct AccountDocumentBlock: Decodable, Equatable {
    let title: String
    let description: String
    let image: String?
    let lastUpdated: String?
    private enum CodingKeys: String, CodingKey { case title, description, image, icon, lastUpdated = "last_updated" }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        title = try container.decodeIfPresent(String.self, forKey: .title) ?? ""
        description = try container.decodeIfPresent(String.self, forKey: .description) ?? ""
        let image = try container.decodeIfPresent(String.self, forKey: .image)
        let icon = try container.decodeIfPresent(String.self, forKey: .icon)
        self.image = [image, icon].compactMap { $0 }.first { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        lastUpdated = try container.decodeIfPresent(String.self, forKey: .lastUpdated)
    }

    var imageURL: URL? {
        guard let image, let url = URL(string: image), ["http", "https"].contains(url.scheme?.lowercased() ?? "") else { return nil }
        return url
    }
    var isEmpty: Bool { title.isEmpty && description.isEmpty && imageURL == nil && (lastUpdated?.isEmpty ?? true) }
}
