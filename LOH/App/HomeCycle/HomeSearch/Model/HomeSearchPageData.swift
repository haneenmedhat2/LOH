import Foundation

/// Content returned by GET search-page before the user submits a search.
struct HomeSearchPageData: Decodable {
    let recentSearches: HomeSearchPageSection
    let suggestions: HomeSearchPageSection
    let mostSearched: HomeSearchPageSection

    private enum CodingKeys: String, CodingKey {
        case recentSearches = "recent_searches"
        case suggestions
        case mostSearched = "most_searched"
    }
}

struct HomeSearchPageSection: Decodable {
    let title: String
    let clearTitle: String?
    let cityID: Int?
    let cityName: String?
    let items: [HomeSearchPageItem]

    private enum CodingKeys: String, CodingKey {
        case title, items
        case clearTitle = "clear_title"
        case cityID = "city_id"
        case cityName = "city_name"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        title = try container.decode(String.self, forKey: .title)
        clearTitle = try container.decodeIfPresent(String.self, forKey: .clearTitle)
        cityID = container.searchPageInt(.cityID)
        cityName = try container.decodeIfPresent(String.self, forKey: .cityName)
        items = try container.decode([HomeSearchPageItem].self, forKey: .items)
    }
}

struct HomeSearchPageItem: Decodable, Hashable {
    let id: Int?
    let rank: Int?
    let keyword: String
    let searchesCount: Int?

    private enum CodingKeys: String, CodingKey {
        case id, rank, keyword, name, title, text, value
        case searchesCount = "searches_count"
    }

    init(from decoder: Decoder) throws {
        if let value = try? decoder.singleValueContainer().decode(String.self) {
            id = nil
            rank = nil
            keyword = value
            searchesCount = nil
            return
        }
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = container.searchPageInt(.id)
        rank = container.searchPageInt(.rank)
        keyword = (try? container.decode(String.self, forKey: .keyword))
            ?? (try? container.decode(String.self, forKey: .name))
            ?? (try? container.decode(String.self, forKey: .title))
            ?? (try? container.decode(String.self, forKey: .text))
            ?? (try? container.decode(String.self, forKey: .value))
            ?? ""
        searchesCount = container.searchPageInt(.searchesCount)
    }

    var query: String? {
        let trimmed = keyword.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    var isDisplayable: Bool { query != nil }
}

private extension KeyedDecodingContainer {
    func searchPageInt(_ key: Key) -> Int? {
        if let value = try? decode(Int.self, forKey: key) { return value }
        if let value = try? decode(String.self, forKey: key) { return Int(value) }
        return nil
    }
}
