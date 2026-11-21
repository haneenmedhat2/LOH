import Foundation

enum ProfileDialog {
    case name, email, birthday, success
    var title: String {
        switch self {
        case .name: return "more.Edit full name".localized
        case .email: return "more.Edit email".localized
        case .birthday: return "more.Edit birthday".localized
        case .success: return "more.Profile saved title".localized
        }
    }
    var screenName: String {
        switch self {
        case .name: return "edit-profile-name"
        case .email: return "edit-profile-email"
        case .birthday: return "edit-profile-dob"
        case .success: return "edit-profile-success"
        }
    }
}

