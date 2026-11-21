//
//  UserDefaults.swift
//  NewSwiftUIBase
//
//  Created by Mohamed Hadwa on 22/07/2025.
//

import Foundation
import Security

@propertyWrapper
struct ValueDefault<Value> {
    
    let key: String
    let defaultValue: Value
    let container: UserDefaults = .standard
    
    var wrappedValue: Value {
        get {
            return container.value(forKey: key) as? Value ?? defaultValue
        }
        set {
            container.setValue(newValue, forKey: key)
        }
    }
}

@propertyWrapper
struct ModelsDefault<Model: Codable> {
    
    let key: String
    let defaultValue: Model
    let container: UserDefaults = .standard
    
    var wrappedValue: Model {
        get {
            let decoder = JSONDecoder()
            guard let decoded = container.object(forKey: key) as? Data else {return defaultValue}
            let loadedValue = try? decoder.decode(Model.self, from: decoded)
            return loadedValue ?? defaultValue
        }
        set {
            let encoder = JSONEncoder()
            if let encoded = try? encoder.encode(newValue) {
                container.set(encoded, forKey: key)
                container.synchronize()
            }
        }
    }
}

extension UserDefaults {
    
    private enum Keys: String {
        case googleMapKey
        case accessToken
        case pushNotificationToken
        case isFirstTime
        case isLogin
        case user
        case apiUser
        case isGuestBrowsing
    }
    
    @ValueDefault(key: Keys.googleMapKey.rawValue, defaultValue: "AIzaSyBd2QY3Km15ITvDCR9Rl6-68HfqqcX0ZqI")
    static var googleMapKey: String
    
    static var accessToken: String? {
        get {
            LegacyAuthTokenStore.removeToken
            return standard.string(forKey: Keys.accessToken.rawValue)
        }
        set {
            LegacyAuthTokenStore.removeToken
            if let newValue {
                standard.set(newValue, forKey: Keys.accessToken.rawValue)
            } else {
                standard.removeObject(forKey: Keys.accessToken.rawValue)
            }
        }
    }

    @ModelsDefault(key: Keys.apiUser.rawValue, defaultValue: nil)
    static var apiUser: APIUser?

    @ValueDefault(key: Keys.isGuestBrowsing.rawValue, defaultValue: false)
    static var isGuestBrowsing: Bool

    static func clearAuthentication() {
        accessToken = nil
        standard.removeObject(forKey: Keys.apiUser.rawValue)
        user = nil
        isLogin = false
        isGuestBrowsing = false
    }

    static func save(_ apiUser: APIUser) {
        var profile = apiUser
        profile.token = nil
        self.apiUser = profile
        user = User(
            countryCode: "966", email: profile.email, fullPhone: profile.fullPhone, id: profile.id,
            image: profile.image, isNotify: profile.isNotify, lang: profile.lang, name: profile.name,
            phone: profile.phone, cityID: profile.cities.first?.id, cityName: profile.cities.first?.name)
    }
    
    @ValueDefault(key: Keys.pushNotificationToken.rawValue, defaultValue: nil)
    static var pushNotificationToken: String?
    
    @ValueDefault(key: Keys.isFirstTime.rawValue, defaultValue: true)
    static var isFirstTime: Bool
    
    @ValueDefault(key: Keys.isLogin.rawValue, defaultValue: false)
    static var isLogin: Bool {
        didSet {
            NotificationCenter.default.post(name: .isLoginChanged, object: nil)
        }
    }
    @ModelsDefault(key: Keys.user.rawValue, defaultValue: nil)
    static var user: User?

    
    
}

private enum LegacyAuthTokenStore {
    // Remove tokens saved by earlier versions. They are never read or migrated.
    static let removeToken: Void = {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: (Bundle.main.bundleIdentifier ?? "LOH") + ".auth",
            kSecAttrAccount as String: "upgrade"
        ]
        _ = SecItemDelete(query as CFDictionary)
    }()
}
