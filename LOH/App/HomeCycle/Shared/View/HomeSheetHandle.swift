import SwiftUI

struct HomeSheetHandle: View {
    var body: some View {
        Capsule()
            .fill(AppColor.border)
            .frame(width: 40, height: 4)
            .padding(.top, 12)
            .padding(.bottom, 4)
            .accessibilityHidden(true)
    }
}
