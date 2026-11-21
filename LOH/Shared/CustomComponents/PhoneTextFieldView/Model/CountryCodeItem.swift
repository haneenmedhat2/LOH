//
//  CountryCodeItem.swift
//  NewSwiftUIBase
//
//  Created by Mohamed Hadwa on 30/07/2025.
//


// MARK: - Protocol for Country

protocol CountryCodeModel: Identifiable, Equatable {
    var pickerId: Int { get }
    var countryCode: String? { get }
    var countryName: String { get }
    var image: String? { get }
}

struct CountriesDataModel: Equatable, CountryCodeModel {
    var id: Int?
    var name: String?
    var key: String?
    var flag: String?

    var pickerId: Int { id ?? 0 }
    var countryCode: String? { key }
    var countryName: String { name ?? "" }
    var image: String? { flag }
}

extension CountriesDataModel: Decodable {
    enum CodingKeys: String, CodingKey {
        case id, name, key, flag, image
        case countryCode = "country_code"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try? container.decode(Int.self, forKey: .id)
        name = try? container.decode(String.self, forKey: .name)
        let code = try container.decodeIfPresent(String.self, forKey: .countryCode)
            ?? container.decodeIfPresent(String.self, forKey: .key)
        key = code.map { $0.hasPrefix("+") ? $0 : "+\($0)" }
        flag = try container.decodeIfPresent(String.self, forKey: .image)
            ?? container.decodeIfPresent(String.self, forKey: .flag)
    }
}
