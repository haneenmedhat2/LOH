import Foundation

struct AccountSettingsViewModel {
    let groups: [AccountSettingsGroup] = [
        .init(title: "more.Account", items: [
            .init(title: "more.Change password", subtitle: "more.Keep your account secure", icon: "Lock", route: .password)
        ]),
        .init(title: "more.Application", items: [
            .init(title: "more.Language", icon: "Globe", route: .language, showsLanguage: true)
        ]),
        .init(title: "more.Privacy and information", items: [
            .init(title: "more.Security and privacy", subtitle: "settings.Security subtitle", icon: "Shield", route: .security),
            .init(title: "more.Terms and conditions", subtitle: "settings.Terms subtitle", icon: "Document", route: .document(.terms)),
            .init(title: "more.About Last Hour", subtitle: "settings.About subtitle", icon: "Info", route: .document(.about))
        ])
    ]
    var version: String { Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0" }
}
