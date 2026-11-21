import SwiftUI

/// Semantic tokens from the LOH customer Figma page (0:1).
enum AppColor {
    static let primary = Color("PrimaryMain")
    static let action = Color("SecondaryMain")
    static let accountCanvas = Color("LOHAccountCanvas")
    static let canvas = Color("BackgroundView")
    static let surface = Color("LOHSurface")
    static let text = Color("LOHTextPrimary")
    static let secondaryText = Color("SecondaryTextFont")
    static let mutedText = Color("LOHTextMuted")
    static let border = Color("LOHBorder")
    static let success = Color("LOHSuccess")
    static let error = Color("errorColor")
    static let errorSurface = Color("secondaryErrorColor")
    static let successSurface = Color("LOHSuccessSurface")
    static let codeSurface = Color("LOHCodeSurface")
    static let codeBorder = Color("LOHCodeBorder")
    static let accentSurface = Color("LOHAccentSurface")
    static let disabledSurface = Color("LOHDisabledSurface")
    static let skeletonSurface = Color("LOHSkeletonSurface")
    static let backIcon = Color("LOHBackIcon")
    static let pageIndicator = Color("LOHPageIndicator")
}
enum AppSpacing {
    static let xxs: CGFloat = 4
    static let xs: CGFloat = 6
    static let small: CGFloat = 8
    static let medium: CGFloat = 12
    static let standard: CGFloat = 16
    static let auth: CGFloat = 20
    static let large: CGFloat = 24
    static let xlarge: CGFloat = 32
}
enum AppRadius {
    static let small: CGFloat = 8
    static let medium: CGFloat = 12
    static let standard: CGFloat = 16
    static let sheet: CGFloat = 24
}
enum AppMetrics {
    static let fieldHeight: CGFloat = 56
    static let buttonHeight: CGFloat = 58
    static let touchTarget: CGFloat = 44
    static let iconSize: CGFloat = 20
}
