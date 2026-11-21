//
//  AuthRoute.swift
//  CTF
//
//  Created by Mohamed Hadwa on 17/11/2025.
//


enum AuthRoute: Hashable {
    case selectCities
    case selectInterests
    case passwordRecovery
    case register
    case terms
    case location
    case accountSuccess
    case verification(phone: String, countryCode: String)
    case completeRegisterData(phone: String, countryCode: String)
}
