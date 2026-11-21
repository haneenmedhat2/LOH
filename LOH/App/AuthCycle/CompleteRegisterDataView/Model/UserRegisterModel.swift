//
//  UserRegisterModel.swift
//  NewSwiftUIBase
//
//  Created by Mohamed Hadwa on 22/07/2025.
//

import Foundation

struct UserRegisterModel: Codable {
    var name: String?
    var phone: String?
    var countryCode: String?
    var email: String?
    var password: String?
    var acceptTerms: Bool? =  false
    var terms:Int?{
        switch acceptTerms {
            case true:
            return 1
        default:
            return 0
        }
    }
}
