import SwiftUI

struct MoreAccountEnvironment: ViewModifier {
    let account: MoreAccountStore

    func body(content: Content) -> some View {
        content
            .environmentObject(account.requests)
            .environmentObject(account.more)
            .environmentObject(account.profile)
            .environmentObject(account.payments)
            .environmentObject(account.tickets)
            .environmentObject(account.notifications)
            .environmentObject(account.language)
    }
}
