import SwiftUI

struct CardContainer<Content: View>: View {
    var padding: CGFloat = AppSpacing.standard
    var cornerRadius: CGFloat = AppRadius.standard
    var background: Color = AppColor.surface
    var border: Color = .clear
    var hasShadow = false
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(background)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(border, lineWidth: 1)
            )
            .shadow(color: hasShadow ? .black.opacity(0.1) : .clear, radius: 3, x: 0, y: 1)
    }
}
