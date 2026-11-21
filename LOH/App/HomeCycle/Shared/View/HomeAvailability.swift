import SwiftUI
import UIKit

struct HomeAvailability: View {
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(AppColor.success)
                .frame(width: 6, height: 6)
            Text(homeText("available"))
                .font(AppFont.regular(size: 10))
        }
        .foregroundStyle(AppColor.success)
    }
}
