import Foundation

struct FAQCategory: Decodable, Identifiable, Hashable {
    let id: Int
    let slug: String
    let title: String
    let icon: String?
    let questionsCount: Int

    enum CodingKeys: String, CodingKey {
        case id, slug, title, icon
        case questionsCount = "questions_count"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        guard let id = c.flexibleInt(.id), id > 0 else { throw APIError.invalidResponse }
        self.id = id
        slug = try c.decodeIfPresent(String.self, forKey: .slug) ?? ""
        title = try c.decode(String.self, forKey: .title)
        icon = try c.decodeIfPresent(String.self, forKey: .icon)
        questionsCount = c.flexibleInt(.questionsCount) ?? 0
    }
}

struct FAQHeader: Decodable {
    let title: String
    let cardTitle: String
    let description: String

    enum CodingKeys: String, CodingKey {
        case title, description
        case cardTitle = "card_title"
    }
}

struct FAQStep: Decodable, Identifiable {
    let number: Int
    let title: String
    let description: String
    let icon: String?
    var id: Int { number }
}

struct FAQQuestion: Decodable, Identifiable {
    let id: Int
    let question: String
    let shortAnswer: String?
    let answer: String?
    let isFeatured: Bool
    let category: FAQCategory?
    let categoryID: Int?
    let steps: [FAQStep]
    let tip: String?

    enum CodingKeys: String, CodingKey {
        case id, question, answer, category, steps, tip
        case shortAnswer = "short_answer", isFeatured = "is_featured"
        case categoryID = "category_id"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        guard let id = c.flexibleInt(.id), id > 0 else { throw APIError.invalidResponse }
        self.id = id
        question = try c.decode(String.self, forKey: .question)
        shortAnswer = try c.decodeIfPresent(String.self, forKey: .shortAnswer)
        answer = try c.decodeIfPresent(String.self, forKey: .answer)
        isFeatured = c.flexibleBool(.isFeatured) ?? false
        category = try c.decodeIfPresent(FAQCategory.self, forKey: .category)
        categoryID = c.flexibleInt(.categoryID) ?? category?.id
        steps = try c.decodeIfPresent([FAQStep].self, forKey: .steps) ?? []
        tip = try c.decodeIfPresent(String.self, forKey: .tip)
    }
}

struct FAQListData: Decodable {
    let header: FAQHeader?
    let categories: [FAQCategory]
    let questions: [FAQQuestion]

    enum CodingKeys: String, CodingKey {
        case header, categories, questions, faqs, popular, featured, data
        case mostSearched = "most_searched", featuredFAQs = "featured_faqs"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        header = try c.decodeIfPresent(FAQHeader.self, forKey: .header)
        categories = try c.decodeIfPresent([FAQCategory].self, forKey: .categories) ?? []
        questions = try c.decodeIfPresent([FAQQuestion].self, forKey: .questions)
            ?? c.decodeIfPresent([FAQQuestion].self, forKey: .faqs)
            ?? c.decodeIfPresent([FAQQuestion].self, forKey: .popular)
            ?? c.decodeIfPresent([FAQQuestion].self, forKey: .featured)
            ?? c.decodeIfPresent([FAQQuestion].self, forKey: .mostSearched)
            ?? c.decodeIfPresent([FAQQuestion].self, forKey: .featuredFAQs)
            ?? c.decodeIfPresent([FAQQuestion].self, forKey: .data)
            ?? []
    }
}
