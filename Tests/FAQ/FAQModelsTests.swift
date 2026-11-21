import Foundation

enum APIError: Error { case invalidResponse }

extension KeyedDecodingContainer {
    func flexibleInt(_ key: Key) -> Int? {
        if let value = try? decode(Int.self, forKey: key) { return value }
        if let value = try? decode(String.self, forKey: key) { return Int(value) }
        return nil
    }
    func flexibleBool(_ key: Key) -> Bool? {
        if let value = try? decode(Bool.self, forKey: key) { return value }
        if let value = flexibleInt(key) { return value != 0 }
        return nil
    }
}

@main struct FAQModelsTests {
    static func main() throws {
        let list = """
        {"header":{"title":"الأسئلة الشائعة","card_title":"كيف نقدر نساعدك؟",
        "description":"اختر سؤالاً من الأسئلة الشائعة أدناه"},
        "categories":[{"id":1,"slug":"purchase","title":"الشراء",
        "icon":"shopping-bag","questions_count":2}],
        "faqs":[{"id":1,"question":"كيف أشتري عرضاً؟",
        "short_answer":"اختر عرضاً من القائمة","is_featured":true,
        "category":{"id":1,"slug":"purchase","title":"الشراء","icon":"shopping-bag"}}]}
        """
        let data = try JSONDecoder().decode(FAQListData.self, from: Data(list.utf8))
        assert(data.header?.cardTitle == "كيف نقدر نساعدك؟")
        assert(data.categories.first?.questionsCount == 2)
        assert(data.questions.first?.id == 1)

        let detail = """
        {"id":1,"question":"كيف أشتري عرضاً؟","short_answer":"اختر عرضاً",
        "is_featured":true,"category":{"id":1,"slug":"purchase",
        "title":"الشراء","icon":"shopping-bag"},
        "answer":"تقدر تشتري أي عرض بخطوات بسيطة",
        "steps":[{"number":1,"title":"اختر العرض",
        "description":"تصفح العروض","icon":"search"}],
        "tip":"بعد نجاح الدفع ستجد العرض مباشرة في صفحة مشترياتي"}
        """
        let question = try JSONDecoder().decode(FAQQuestion.self, from: Data(detail.utf8))
        assert(question.steps.first?.number == 1)
        assert(question.tip?.contains("مشترياتي") == true)
        print("FAQ model tests passed")
    }
}
