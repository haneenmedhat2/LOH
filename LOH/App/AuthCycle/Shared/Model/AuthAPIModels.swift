import Foundation

struct AuthOption: Codable, Identifiable, Hashable {
    let id: Int
    let name: String
    let isSelected: Bool
    init(id: Int, name: String, isSelected: Bool) {
        self.id = id
        self.name = name
        self.isSelected = isSelected
    }
    enum CodingKeys: String, CodingKey { case id, name; case isSelected = "is_selected" }
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        guard let id = c.flexibleInt(.id) else { throw APIError.invalidResponse }
        self.id = id; name = try c.decode(String.self, forKey: .name)
        isSelected = c.flexibleBool(.isSelected) ?? false
    }
}
struct APIUser: Codable {
    let id: Int
    var name: String?
    var email: String?
    var phone: String?
    var fullPhone: String?
    var image: String?
    var lang: String?
    var isNotify: Bool?
    var token: String?
    var gender: String?
    var birthDate: String?
    var cities: [AuthOption]
    var interests: [AuthOption]
    enum CodingKeys: String, CodingKey {
        case id, name, email, phone, image, lang, token, cities, interests
        case fullPhone = "full_phone", isNotify = "is_notify"
        case gender, birthDate = "birth_date"
    }
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        guard let id = c.flexibleInt(.id) else { throw APIError.invalidResponse }
        self.id = id
        name = try c.decodeIfPresent(String.self, forKey: .name)
        email = try c.decodeIfPresent(String.self, forKey: .email)
        phone = try c.decodeIfPresent(String.self, forKey: .phone)
        fullPhone = try c.decodeIfPresent(String.self, forKey: .fullPhone)
        image = try c.decodeIfPresent(String.self, forKey: .image)
        lang = try c.decodeIfPresent(String.self, forKey: .lang)
        isNotify = c.flexibleBool(.isNotify)
        token = try c.decodeIfPresent(String.self, forKey: .token)
        gender = try c.decodeIfPresent(String.self, forKey: .gender)
        birthDate = try c.decodeIfPresent(String.self, forKey: .birthDate)
        cities = try c.decodeIfPresent([AuthOption].self, forKey: .cities) ?? []
        interests = try c.decodeIfPresent([AuthOption].self, forKey: .interests) ?? []
    }
}
struct SignupData: Decodable { let user: APIUser }

