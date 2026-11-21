import Foundation

struct AccountSettingsItem: Identifiable {
    let title: String
    var subtitle: String = ""
    let icon: String
    let route: MoreCoordinatorRoute
    var showsLanguage = false
    var id: String { title }
}

struct AccountSettingsGroup: Identifiable {
    let title: String
    let items: [AccountSettingsItem]
    var id: String { title }
}
