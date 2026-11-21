import Foundation

enum AccountDeletionStep {
    case introduction, confirmation, processing, completed
}

struct AccountDeletionReason: Identifiable {
    let id: String
    static let all = ["settings.Delete unused", "settings.Delete better app", "settings.Delete service",
                      "settings.Delete privacy", "more.Other"].map { AccountDeletionReason(id: $0) }
}
