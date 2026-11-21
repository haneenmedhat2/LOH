import SwiftUI

struct HomeFilterChip: View {
    let title: String
    var selected = false
    var star = false
    var expand = false
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if star {
                    HomeIcon.star.view(12)
                }
                Text(title)
                    .font(selected ? AppFont.bold(size: 13) : AppFont.regular(size: 13))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .padding(.horizontal, 14)
            .frame(maxWidth: expand ? .infinity : nil, minHeight: 42)
            .foregroundStyle(selected ? AppColor.surface : AppColor.text)
            .background(selected ? AppColor.primary : AppColor.surface, in: RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(selected ? AppColor.primary : AppColor.border))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}

/// Wrap category chips at their natural widths, retaining their order in either layout direction.
struct HomeFilterFlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(subviews, width: proposal.width ?? .infinity)
        return CGSize(width: proposal.width ?? result.size.width, height: result.size.height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(subviews, width: bounds.width)
        for (index, frame) in result.frames.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + frame.minX, y: bounds.minY + frame.minY),
                anchor: .topLeading,
                proposal: ProposedViewSize(width: frame.width, height: frame.height))
        }
    }

    private func arrange(_ subviews: Subviews, width: CGFloat) -> (frames: [CGRect], size: CGSize) {
        var frames: [CGRect] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var usedWidth: CGFloat = 0
        for subview in subviews {
            let ideal = subview.sizeThatFits(.unspecified)
            let itemWidth = min(ideal.width, width)
            let size = subview.sizeThatFits(ProposedViewSize(width: itemWidth, height: nil))
            if x > 0 && x + itemWidth > width {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            frames.append(CGRect(x: x, y: y, width: itemWidth, height: size.height))
            usedWidth = max(usedWidth, x + itemWidth)
            x += itemWidth + spacing
            rowHeight = max(rowHeight, size.height)
        }
        return (frames, CGSize(width: usedWidth, height: y + rowHeight))
    }
}
