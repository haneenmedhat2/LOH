import Foundation

struct NewTicketForm {
    var category = ""
    var relatedOrder = ""
    var title = ""
    var details = ""
    var submission: SupportTicketSubmission? {
        guard let typeID = Int(category),
              relatedOrder.isEmpty || Int(relatedOrder) != nil
        else { return nil }
        let value = SupportTicketSubmission(typeID: typeID, orderID: Int(relatedOrder), title: title, description: details)
        return value.isValid ? value : nil
    }
    var valid: Bool { submission != nil }
}
