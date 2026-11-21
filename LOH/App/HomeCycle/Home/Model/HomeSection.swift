//
//  HomeSection.swift
//  CTF
//
//  Created by Mohamed Hadwa on 08/12/2025.
//


import Foundation

struct HomeData: Codable {
    var images: [ImageModel]?
    var categories: [CategoryModel]?
}

struct ImageModel: Identifiable, Codable, Hashable {
    var id: Int?
    var image: String?
    
}

struct CategoryModel: Identifiable, Codable {
    var id: Int
    var name: String
    var description: String
    var image: String
}

enum HomeSheet: String, Identifiable {
    case city, filters, cashback
    var id: String { rawValue }
}
