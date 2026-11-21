import Foundation


enum SupportTicketStatus: String, CaseIterable {
    case all, open, inProgress = "in_progress", closed
}

struct SupportTicketSubmission {
    let typeID: Int
    let orderID: Int?
    let title: String
    let description: String

    var isValid: Bool {
        typeID > 0 && (orderID.map { $0 > 0 } ?? true)
            && (1...191).contains(title.trimmingCharacters(in: .whitespacesAndNewlines).count)
            && (2...1000).contains(description.trimmingCharacters(in: .whitespacesAndNewlines).count)
    }
}

