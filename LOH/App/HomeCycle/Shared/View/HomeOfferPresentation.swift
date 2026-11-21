import SwiftUI
import UIKit

extension HomeOffer {
    var displayTitle: String {
        guard isRemote else {
            return homeText(title)
        }
        return title.isEmpty ? (categoryName ?? homeText("offerLabel")) : title
    }
    var displayMerchant: String { isRemote ? merchant : homeText(merchant) }
}
