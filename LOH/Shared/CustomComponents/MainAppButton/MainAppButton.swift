import SwiftUI

typealias VoidCompletion = () -> Void

extension LinearGradient {
    /// Compatibility API for callers in the base project.
    static var mainVertical: LinearGradient {
        LinearGradient(colors: [AppColor.primary, AppColor.primary], startPoint: .top, endPoint: .bottom)
    }
}
enum AppButtonVariant: CaseIterable {
    case primary, action, outlined, secondary, destructive
    var background: Color {
        switch self {
        case .primary: return AppColor.primary
        case .action: return AppColor.action
        case .outlined, .secondary: return AppColor.surface
        case .destructive: return AppColor.error
        }
    }
    var foreground: Color {
        switch self {
        case .outlined: return AppColor.primary
        case .secondary: return AppColor.text
        default: return AppColor.surface
        }
    }
    var border: Color {
        switch self {
        case .outlined: return AppColor.primary
        case .secondary: return AppColor.border
        default: return .clear
        }
    }
}
struct MainAppButton: View {
    let title: String
    let action: VoidCompletion
    var variant: AppButtonVariant = .primary
    var isLoading = false
    var isEnabled = true
    var icon: Image? = nil
    var height: CGFloat = AppMetrics.buttonHeight
    var iconSize: CGFloat = 20

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.small) {
                if isLoading {
                    BrandLoaderView(size: 28)
                } else if let icon {
                    icon
                        .resizable()
                        .scaledToFit()
                        .frame(width: iconSize, height: iconSize)
                }
                Text(title)
                    .multilineTextAlignment(.center)
            }
        }
        .buttonStyle(MainButtonStyle(variant: variant, isLoading: isLoading, height: height))
        .disabled(!isEnabled || isLoading)
        .accessibilityLabel(title)
        .accessibilityValue(isLoading ? "Loading".localized : "")
    }
}
struct MainButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var variant: AppButtonVariant = .primary
    var isLoading = false
    var background: LinearGradient? = nil
    var foregroundColor: Color? = nil
    var height: CGFloat = AppMetrics.buttonHeight
    var cornerRadius: CGFloat = AppRadius.standard
    var horizontalPadding: CGFloat = 0
    var font: Font = AppFont.button

    func makeBody(configuration: Configuration) -> some View {
        let active = isEnabled || isLoading
        let fill =
            active
            ? (background.map { AnyShapeStyle($0) } ?? AnyShapeStyle(variant.background))
            : AnyShapeStyle(AppColor.disabledSurface)
        configuration.label
            .font(font)
            .padding(.horizontal, AppSpacing.standard)
            .padding(.vertical, AppSpacing.medium)
            .frame(maxWidth: .infinity, minHeight: height)
            .foregroundStyle(active ? (foregroundColor ?? variant.foreground) : AppColor.mutedText)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(fill)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(active ? variant.border : .clear, lineWidth: 1)
            )
            .padding(.horizontal, horizontalPadding)
            .opacity(configuration.isPressed ? 0.85 : 1)
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.98 : 1)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.15), value: configuration.isPressed)
    }
}
