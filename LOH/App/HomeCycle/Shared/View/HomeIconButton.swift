import SwiftUI
import UIKit

struct HomeIconButton: View {
    let icon: HomeIcon
    let label: String
    var color: Color? = nil
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            icon.view(20, color: color)
                .frame(width: 40, height: 40)
                .background(AppColor.surface, in: Circle())
                .overlay(
                    Circle()
                        .stroke(AppColor.border.opacity(0.6), lineWidth: 1)
                )
                .frame(minWidth: 44, minHeight: 44)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(homeText(label))
    }
}
