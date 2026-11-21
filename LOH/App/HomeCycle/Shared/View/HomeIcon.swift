import SwiftUI
import UIKit

enum HomeIcon: String, CaseIterable {
    case heart, heartFilled, share, back, verified, merchantLogo, pin, star, lock, calendar, ticket, check
    case directions, clock, plus, minus, close, history, trend, bell, cashback, cafe, restaurant
    case emptySearch, magnifier, purchasesEmpty, sun, notificationCheck, searchLoader
    case emptyEntertainment, emptyCafe, emptyRestaurant
    case homeInactive, paymentShield, mada, cards, paymentCashback, applePay, orderClock, notificationStar
    var asset: String { "lohHome" + rawValue.prefix(1).uppercased() + rawValue.dropFirst() }
    var image: Image { Image(asset) }
    func view(_ size: CGFloat, color: Color? = nil) -> some View {
        image
            .renderingMode(color == nil ? .original : .template)
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .foregroundStyle(color ?? AppColor.text)
            .accessibilityHidden(true)
    }
}
