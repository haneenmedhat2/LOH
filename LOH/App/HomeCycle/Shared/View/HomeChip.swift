import SwiftUI
import UIKit

struct HomeChip: View {
    let title: String
    var selected = false
    var height: CGFloat = 38
    var cornerRadius: CGFloat = 14
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(selected ? AppFont.bold(size: 13) : AppFont.regular(size: 13))
                .foregroundStyle(selected ? AppColor.surface : AppColor.secondaryText)
                .padding(.horizontal, 16)
                .frame(minHeight: height)
                .background(
                    selected ? AppColor.primary : AppColor.surface, in: RoundedRectangle(cornerRadius: cornerRadius)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(selected ? .clear : AppColor.border, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}
