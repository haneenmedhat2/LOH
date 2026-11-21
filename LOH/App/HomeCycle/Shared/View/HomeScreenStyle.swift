import SwiftUI
import UIKit

struct HomeScreenStyle: ViewModifier {
    let title: String
    var bodyColor = AppColor.canvas
    var navigationColor: Color? = nil
    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                bodyColor
                    .ignoresSafeArea()
            )
            .foregroundStyle(AppColor.text)
            .modifier(AppNavigationBarModifier(title: title, background: navigationColor ?? bodyColor))
    }
}
