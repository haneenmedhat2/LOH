import SwiftUI

struct HomeRadio: View {
    let selected: Bool
    var body: some View {
        Circle()
            .stroke(selected ? AppColor.primary : Color(.systemGray3), lineWidth: 2)
            .frame(width: 20, height: 20)
            .overlay {
                if selected {
                    Circle()
                        .fill(AppColor.primary)
                        .frame(width: 12, height: 12)
                }
            }
            .accessibilityHidden(true)
    }
}
