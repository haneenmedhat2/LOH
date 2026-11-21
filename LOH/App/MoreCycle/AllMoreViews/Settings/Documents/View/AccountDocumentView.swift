import SwiftUI

struct AccountDocumentView: View {
    let document: AccountDocument
    private var title: String {
        switch document {
        case .privacy: return "more.Privacy policy".localized
        case .terms: return "more.Terms and conditions".localized
        case .about: return "more.About Last Hour".localized
        }
    }
    var body: some View {
        AccountPage(title: title, headerHeight: 60) {
            AccountRemoteDocument(endpoint: document.endpoint)
        }
    }
}
