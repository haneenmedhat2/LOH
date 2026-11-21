import Foundation

struct AccountPasswordForm {
    var current = ""
    var password = ""
    var confirmation = ""

    var valid: Bool {
        AccountValidation.validPasswordChange(current: current, new: password, confirmation: confirmation)
    }
}
