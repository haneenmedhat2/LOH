import SwiftUI

/// Search placeholders from Figma's search-loading screen (13:10995).
struct HomeSearchLoadingView: View {
    @ObservedObject private var language = AppLanguageManager.shared

    private var loadingMessage: String {
        HomeLocalization(language: language.apiLanguage).text("loadingNearbyOffers")
    }

    var body: some View {
        VStack(spacing: 12) {
            HomeSearchLoadingIndicator()
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)

            ForEach(0..<3, id: \.self) { _ in
                HomeSearchSkeletonRow()
            }

            Text(loadingMessage)
                .font(AppFont.regular(size: 13))
                .foregroundStyle(AppColor.mutedText)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
        }
        .allowsHitTesting(false)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(loadingMessage)
        .accessibilityAddTraits(.updatesFrequently)
    }
}

private struct HomeSearchLoadingIndicator: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var rotating = false

    var body: some View {
        HomeIcon.searchLoader.view(32)
            .rotationEffect(.degrees(rotating ? 360 : 0))
            .animation(reduceMotion ? nil : .linear(duration: 1).repeatForever(autoreverses: false), value: rotating)
            .onAppear { rotating = !reduceMotion }
            .onChange(of: reduceMotion) { rotating = !$0 }
    }
}

private struct HomeSearchSkeletonRow: View {
    var body: some View {
        HStack(spacing: 0) {
            LinearGradient(
                colors: [AppColor.skeletonSurface, AppColor.border, AppColor.skeletonSurface],
                startPoint: .leading, endPoint: .trailing
            )
            .frame(width: 112)

            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top, spacing: 8) {
                    Circle()
                        .fill(AppColor.skeletonSurface)
                        .frame(width: 32, height: 32)

                    VStack(alignment: .leading, spacing: 8) {
                        bar(width: 115, height: 16)
                        bar(width: 86, height: 12)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                HStack(spacing: 8) {
                    bar(width: 56, height: 24)
                    bar(width: 40, height: 24)
                }

                bar(width: 165, height: 12)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.top, 4)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(height: 118)
        .background(AppColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(AppColor.disabledSurface, lineWidth: 1))
    }

    private func bar(width: CGFloat, height: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(AppColor.skeletonSurface)
            .frame(maxWidth: width)
            .frame(height: height)
    }
}

#Preview("Search loading · Arabic") {
    HomeSearchLoadingView()
        .padding(16)
        .background(AppColor.canvas)
        .environment(\.layoutDirection, .rightToLeft)
}
