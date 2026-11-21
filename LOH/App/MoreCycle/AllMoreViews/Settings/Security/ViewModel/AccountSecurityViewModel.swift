import Foundation

struct AccountSecurityViewModel {
    let content = AccountSecurityContent()
    var policyRoute: MoreCoordinatorRoute { .document(content.policy) }
}
