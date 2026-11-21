import SwiftUI

/// A two-ended distance range, measured in whole kilometers from zero to ten.
struct HomeDistanceRangeSlider: View {
    @Binding var minimum: Double
    @Binding var maximum: Double
    @State private var activeThumb: Thumb?
    private let limit: Double = 10
    private let thumbDiameter: CGFloat = 20

    private enum Thumb { case minimum, maximum }

    var body: some View {
        GeometryReader { geometry in
            let inset = thumbDiameter / 2
            let width = max(geometry.size.width - thumbDiameter, 1)
            let minimumX = inset + width * CGFloat(minimum / limit)
            let maximumX = inset + width * CGFloat(maximum / limit)
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(AppColor.disabledSurface)
                    .frame(height: 6)
                    .padding(.horizontal, inset)
                Capsule()
                    .fill(AppColor.primary)
                    .frame(width: max(0, maximumX - minimumX), height: 6)
                    .offset(x: minimumX)
                thumb(.minimum)
                    .position(x: minimumX, y: geometry.size.height / 2)
                thumb(.maximum)
                    .position(x: maximumX, y: geometry.size.height / 2)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        if activeThumb == nil {
                            let start = gesture.startLocation.x
                            let lowerDistance = abs(start - minimumX)
                            let upperDistance = abs(start - maximumX)
                            if abs(lowerDistance - upperDistance) < 0.5 && abs(gesture.translation.width) < 1 {
                                return
                            }
                            activeThumb = abs(lowerDistance - upperDistance) < 0.5
                                ? (gesture.translation.width < 0 ? .minimum : .maximum)
                                : (lowerDistance < upperDistance ? .minimum : .maximum)
                        }
                        let value = (Double((gesture.location.x - inset) / width) * limit).rounded()
                        setValue(value, for: activeThumb!)
                    }
                    .onEnded { _ in activeThumb = nil }
            )
        }
        .frame(height: 44)
        .environment(\.layoutDirection, .leftToRight)
    }

    private func thumb(_ which: Thumb) -> some View {
        Circle()
            .fill(AppColor.primary)
            .frame(width: thumbDiameter, height: thumbDiameter)
            .overlay(Circle().strokeBorder(AppColor.surface, lineWidth: 2))
            .shadow(color: .black.opacity(0.18), radius: 3, y: 2)
            .frame(width: 44, height: 44)
            .accessibilityElement()
            .accessibilityLabel(homeText(which == .minimum ? "minimumDistance" : "maximumDistance"))
            .accessibilityValue(homeDistance(which == .minimum ? minimum : maximum))
            .accessibilityAdjustableAction { direction in
                let current = which == .minimum ? minimum : maximum
                switch direction {
                case .increment: setValue(current + 1, for: which)
                case .decrement: setValue(current - 1, for: which)
                @unknown default: break
                }
            }
    }

    private func setValue(_ value: Double, for thumb: Thumb) {
        let value = min(limit, max(0, value))
        switch thumb {
        case .minimum: minimum = min(value, maximum)
        case .maximum: maximum = max(value, minimum)
        }
    }
}
