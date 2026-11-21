//
//  Language.swift
//  NewSwiftUIBase
//
//  Created by Mohamed Hadwa on 22/07/2025.
//

import Foundation
import SwiftUI

class AppLanguageManager: ObservableObject {
    static let shared = AppLanguageManager()
    
    private let defaults: UserDefaults
    private let preferredLanguages: () -> [String]

    @Published private(set) var selectedLanguage: String {
        didSet {
            // Cache for legacy string helpers and API headers, not the source of truth.
            defaults.set(selectedLanguage, forKey: "selectedLanguage")
        }
    }

    init(defaults: UserDefaults = .standard,
         preferredLanguages: @escaping () -> [String] = { Locale.preferredLanguages }) {
        self.defaults = defaults
        self.preferredLanguages = preferredLanguages
        let languages = defaults.stringArray(forKey: "AppleLanguages") ?? preferredLanguages()
        selectedLanguage = Self.supportedLanguage(in: languages)
        defaults.set(selectedLanguage, forKey: "selectedLanguage")
        // Do not overwrite the language selected in iOS Settings at startup.
    }

    private static func supportedLanguage(in languages: [String]) -> String {
        for identifier in languages {
            let code = identifier.lowercased().replacingOccurrences(of: "_", with: "-").split(separator: "-").first
            if code == "ar" { return "ar" }
            if code == "en" { return "en" }
        }
        return "en"
    }

    func refreshFromSystem() {
        let languages = defaults.stringArray(forKey: "AppleLanguages") ?? preferredLanguages()
        let code = Self.supportedLanguage(in: languages)
        if code != selectedLanguage { selectedLanguage = code }
    }

    enum Languages {
        static let en = "en"
        static let ar = "ar"
    }
    
    static func currentLanguage() -> String {
        shared.selectedLanguage
    }
    static func setAppLanguage(lang: String) {
        shared.setLanguage(lang)
    }

    static func apiLanguage() -> String {
        return self.currentLanguage().contains(Languages.ar) ? Languages.ar : Languages.en
    }
    
    static func currentLang() -> appLanguage {
        return self.currentLanguage().contains(Languages.ar) ? .arabic : .english
    }
    
    static func isRTL() -> Bool {
        return self.currentLanguage().contains(Languages.ar) ? true : false
    }
    
    var apiLanguage: String {
        selectedLanguage.contains("ar") ? "ar" : "en"
    }
    var isRTL: Bool {
        selectedLanguage == "ar"
    }
    
    var layoutDirection: LayoutDirection {
        selectedLanguage == "ar" ? .rightToLeft : .leftToRight
    }

    func toggleLanguage() {
        setLanguage(selectedLanguage == "ar" ? "en" : "ar")
    }

    func setLanguage(_ lang: String) {
        let code = Self.supportedLanguage(in: [lang])
        defaults.set([code], forKey: "AppleLanguages")
        if code != selectedLanguage { selectedLanguage = code }
    }
}

extension String {
    var localized: String {
        let language = UserDefaults.standard.string(forKey: "selectedLanguage") ?? "en"
        guard let path = Bundle.main.path(forResource: language, ofType: "lproj"),
              let bundle = Bundle(path: path) else { return NSLocalizedString(self, comment: "") }
        return bundle.localizedString(forKey: self, value: nil, table: nil)
    }
    var validationLocalized: String {
        return NSLocalizedString(self, tableName: "ValidationLocalized", bundle: Bundle.main, value: "", comment: "")
    }
    var helperLocalizable: String {
        return NSLocalizedString(self, tableName: "HelperLocalizable", bundle: Bundle.main, value: "", comment: "")
    }
    
}
enum appLanguage: String {
    case english = "en"
    case arabic = "ar"
}
